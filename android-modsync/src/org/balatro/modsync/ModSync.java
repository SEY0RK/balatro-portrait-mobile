package org.balatro.modsync;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.Process;
import android.util.Log;
import android.widget.Toast;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.security.MessageDigest;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/**
 * Imports user-provided MOD zip files from one deliberately fixed public folder.
 * Never searches or reads any other Download folder.
 */
public final class ModSync {
    private static final String TAG = "BalatroModSync";
    private static final String SOURCE_PATH =
            "/storage/emulated/0/Download/balatro portrait mod";
    private static final int REQUEST_CODE = 7731;
    private static final long MAX_UNPACKED_BYTES = 512L * 1024L * 1024L;
    private static volatile boolean running = false;

    private ModSync() {}

    public static void onResume(final Activity activity) {
        if (activity == null || activity.isFinishing() || running) return;
        if (!hasAllFilesAccess()) {
            promptForAccess(activity);
            return;
        }
        synchronized (ModSync.class) {
            if (running) return;
            running = true;
        }
        Thread worker = new Thread(new Runnable() {
            @Override public void run() {
                final String result;
                try {
                    result = sync(activity);
                } catch (final Exception e) {
                    Log.e(TAG, "MOD sync failed", e);
                    activity.runOnUiThread(new Runnable() {
                        @Override public void run() {
                            running = false;
                            if (!activity.isFinishing()) {
                                new AlertDialog.Builder(activity)
                                    .setTitle("MOD 同步失败")
                                    .setMessage("无法导入 MOD 压缩包：\n" + e.getMessage())
                                    .setPositiveButton("知道了", null)
                                    .show();
                            }
                        }
                    });
                    return;
                }
                activity.runOnUiThread(new Runnable() {
                    @Override public void run() {
                        running = false;
                        if (activity.isFinishing()) return;
                        if (result.startsWith("UPDATED:")) {
                            String count = result.substring("UPDATED:".length());
                            new AlertDialog.Builder(activity)
                                .setTitle("MOD 已同步")
                                .setMessage("已从指定目录导入 " + count
                                    + " 个 MOD 压缩包。需要重启游戏一次，MOD 才会被加载。")
                                .setCancelable(false)
                                .setPositiveButton("立即重启", new DialogInterface.OnClickListener() {
                                    @Override public void onClick(DialogInterface dialog, int which) {
                                        restart(activity);
                                    }
                                })
                                .setNegativeButton("稍后", null)
                                .show();
                        } else if ("MISSING".equals(result)) {
                            Toast.makeText(activity,
                                "请将 MOD ZIP 放入 Download/balatro portrait mod 文件夹",
                                Toast.LENGTH_LONG).show();
                        }
                    }
                });
            }
        }, "BalatroModSync");
        worker.setDaemon(true);
        worker.start();
    }

    private static boolean hasAllFilesAccess() {
        if (Build.VERSION.SDK_INT < 30) return true;
        try {
            return ((Boolean) Environment.class.getMethod("isExternalStorageManager")
                    .invoke(null)).booleanValue();
        } catch (Throwable t) {
            Log.e(TAG, "Cannot check all-files access", t);
            return false;
        }
    }

    private static void promptForAccess(final Activity activity) {
        final android.content.SharedPreferences prefs =
            activity.getSharedPreferences("balatro_mod_sync", 0);
        if (prefs.getBoolean("access_prompt_shown", false)) {
            new AlertDialog.Builder(activity)
                .setTitle("需要文件访问权限")
                .setMessage("为了读取指定目录中的 MOD ZIP，需要允许本游戏管理所有文件。")
                .setPositiveButton("打开设置", new DialogInterface.OnClickListener() {
                    @Override public void onClick(DialogInterface d, int w) {
                        openAccessSettings(activity);
                    }
                })
                .setNegativeButton("暂不", null)
                .show();
            return;
        }
        prefs.edit().putBoolean("access_prompt_shown", true).apply();
        new AlertDialog.Builder(activity)
            .setTitle("设置 MOD 文件夹访问")
            .setMessage("首次使用 MOD 导入功能，需要授予“允许管理所有文件”权限。游戏只会读取：\n"
                + SOURCE_PATH + "\n不会访问其他游戏的 MOD 文件夹。")
            .setCancelable(false)
            .setPositiveButton("前往授权", new DialogInterface.OnClickListener() {
                @Override public void onClick(DialogInterface d, int w) {
                    openAccessSettings(activity);
                }
            })
            .setNegativeButton("暂不", null)
            .show();
    }

    private static void openAccessSettings(Activity activity) {
        try {
            Intent intent = new Intent("android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION");
            intent.setData(Uri.parse("package:" + activity.getPackageName()));
            activity.startActivityForResult(intent, REQUEST_CODE);
        } catch (Throwable first) {
            try {
                Intent fallback = new Intent("android.settings.APPLICATION_DETAILS_SETTINGS");
                fallback.setData(Uri.parse("package:" + activity.getPackageName()));
                activity.startActivity(fallback);
            } catch (Throwable second) {
                Toast.makeText(activity, "无法打开权限设置，请在系统设置中手动授权。",
                    Toast.LENGTH_LONG).show();
            }
        }
    }

    private static String sync(Activity activity) throws Exception {
        File source = new File(SOURCE_PATH);
        if (!source.exists()) {
            if (!source.mkdirs() && !source.isDirectory()) {
                throw new Exception("无法创建 MOD 文件夹：" + SOURCE_PATH);
            }
            return "MISSING";
        }
        if (!source.isDirectory()) throw new Exception("MOD 来源路径不是文件夹。");

        File appFiles = activity.getFilesDir();
        File mods = new File(appFiles, "save/ASET/Mods");
        if (!mods.exists() && !mods.mkdirs()) throw new Exception("无法创建 Lovely Mods 目录。");

        File[] files = source.listFiles();
        if (files == null) throw new Exception("无法读取指定 MOD 文件夹。");
        int updated = 0;
        android.content.SharedPreferences prefs =
            activity.getSharedPreferences("balatro_mod_sync", 0);
        android.content.SharedPreferences.Editor editor = prefs.edit();

        for (File zip : files) {
            if (!zip.isFile() || !zip.getName().toLowerCase(Locale.ROOT).endsWith(".zip")) continue;
            String digest = sha256(zip);
            String key = "zip:" + zip.getName();
            if (digest.equals(prefs.getString(key, ""))) continue;

            File stagingBase = new File(activity.getCacheDir(), "modsync");
            if (!stagingBase.exists() && !stagingBase.mkdirs()) {
                throw new Exception("无法创建临时解压目录。");
            }
            File staging = new File(stagingBase, "import-" + updated + "-" + System.nanoTime());
            if (!staging.mkdirs()) throw new Exception("无法创建临时导入目录。");

            String root = unzipOneRoot(zip, staging);
            if (root == null || root.length() == 0) {
                deleteTree(staging);
                throw new Exception(zip.getName() + " 不符合“ZIP 内含一个顶层 MOD 文件夹”的结构。");
            }
            File extractedRoot = new File(staging, root);
            if (!extractedRoot.isDirectory()) {
                deleteTree(staging);
                throw new Exception(zip.getName() + " 中未找到顶层 MOD 文件夹。");
            }
            File destination = new File(mods, root);
            copyTree(extractedRoot, destination);
            deleteTree(staging);
            editor.putString(key, digest);
            updated++;
        }
        editor.apply();
        return updated > 0 ? "UPDATED:" + updated : "UNCHANGED";
    }

    private static String unzipOneRoot(File zip, File staging) throws Exception {
        ZipInputStream in = new ZipInputStream(new BufferedInputStream(new FileInputStream(zip)));
        String root = null;
        long total = 0;
        byte[] buffer = new byte[32768];
        try {
            ZipEntry entry;
            while ((entry = in.getNextEntry()) != null) {
                String name = entry.getName().replace('\\', '/');
                if (name.startsWith("/") || name.indexOf(':') >= 0) {
                    throw new Exception("ZIP 含有不安全路径：" + name);
                }
                String[] parts = name.split("/");
                if (parts.length == 0 || parts[0].length() == 0
                        || ".".equals(parts[0]) || "..".equals(parts[0])) {
                    throw new Exception("ZIP 顶层目录无效：" + name);
                }
                if (root == null) root = parts[0];
                if (!root.equals(parts[0])) {
                    throw new Exception("一个 ZIP 中必须只有一个顶层 MOD 文件夹。");
                }
                File out = new File(staging, name);
                String base = staging.getCanonicalPath() + File.separator;
                if (!out.getCanonicalPath().startsWith(base)) {
                    throw new Exception("ZIP 路径越界：" + name);
                }
                if (entry.isDirectory()) {
                    if (!out.exists() && !out.mkdirs()) throw new Exception("无法创建解压目录。");
                } else {
                    File parent = out.getParentFile();
                    if (!parent.exists() && !parent.mkdirs()) throw new Exception("无法创建解压目录。");
                    BufferedOutputStream output = new BufferedOutputStream(new FileOutputStream(out));
                    try {
                        int n;
                        while ((n = in.read(buffer)) != -1) {
                            total += n;
                            if (total > MAX_UNPACKED_BYTES) {
                                throw new Exception("单个 ZIP 解压后超过 512 MB，已中止。");
                            }
                            output.write(buffer, 0, n);
                        }
                    } finally {
                        output.close();
                    }
                }
                in.closeEntry();
            }
        } finally {
            in.close();
        }
        return root;
    }

    private static void copyTree(File source, File destination) throws Exception {
        if (source.isDirectory()) {
            if (!destination.exists() && !destination.mkdirs()) {
                throw new Exception("无法创建 MOD 目标目录：" + destination);
            }
            File[] children = source.listFiles();
            if (children == null) throw new Exception("无法读取解压后的 MOD 文件夹。");
            for (File child : children) copyTree(child, new File(destination, child.getName()));
        } else {
            File parent = destination.getParentFile();
            if (!parent.exists() && !parent.mkdirs()) throw new Exception("无法创建 MOD 文件目录。");
            InputStream in = new BufferedInputStream(new FileInputStream(source));
            BufferedOutputStream out = new BufferedOutputStream(new FileOutputStream(destination));
            try {
                byte[] buffer = new byte[32768];
                int n;
                while ((n = in.read(buffer)) != -1) out.write(buffer, 0, n);
            } finally {
                try { in.close(); } finally { out.close(); }
            }
        }
    }

    private static String sha256(File file) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        InputStream in = new BufferedInputStream(new FileInputStream(file));
        try {
            byte[] buffer = new byte[32768];
            int n;
            while ((n = in.read(buffer)) != -1) digest.update(buffer, 0, n);
        } finally {
            in.close();
        }
        byte[] bytes = digest.digest();
        StringBuilder value = new StringBuilder();
        for (byte b : bytes) value.append(String.format(Locale.US, "%02x", b & 0xff));
        return value.toString();
    }

    private static void deleteTree(File file) {
        if (file == null || !file.exists()) return;
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) for (File child : children) deleteTree(child);
        }
        file.delete();
    }

    private static void restart(Activity activity) {
        try {
            Intent launch = activity.getPackageManager()
                .getLaunchIntentForPackage(activity.getPackageName());
            if (launch != null) {
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                activity.startActivity(launch);
            }
        } catch (Throwable t) {
            Log.e(TAG, "Could not relaunch activity", t);
        }
        activity.finish();
        Process.killProcess(Process.myPid());
    }
}
