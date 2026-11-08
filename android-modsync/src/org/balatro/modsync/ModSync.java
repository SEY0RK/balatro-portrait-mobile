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
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
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
        if (!source.exists() && !source.mkdirs() && !source.isDirectory()) {
            throw new Exception("无法创建 MOD 文件夹：" + SOURCE_PATH);
        }
        if (!source.isDirectory()) throw new Exception("MOD 来源路径不是文件夹。");

        File appFiles = activity.getFilesDir();
        File mods = new File(appFiles, "save/ASET/Mods");
        if (!mods.exists() && !mods.mkdirs()) throw new Exception("无法创建 Lovely Mods 目录。");

        android.content.SharedPreferences prefs =
            activity.getSharedPreferences("balatro_mod_sync", 0);
        Map<String, String> previous = new HashMap<String, String>();
        for (Map.Entry<String, ?> entry : prefs.getAll().entrySet()) {
            String key = entry.getKey();
            if (key.startsWith("managed:zip:") && entry.getValue() instanceof String) {
                previous.put(key.substring("managed:zip:".length()), (String) entry.getValue());
            }
        }

        File[] listed = source.listFiles();
        if (listed == null) throw new Exception("无法读取指定 MOD 文件夹。");
        List<File> archives = new ArrayList<File>();
        for (File file : listed) {
            if (file.isFile() && file.getName().toLowerCase(Locale.ROOT).endsWith(".zip")) {
                archives.add(file);
            }
        }
        Collections.sort(archives, new Comparator<File>() {
            @Override public int compare(File a, File b) {
                return a.getName().compareToIgnoreCase(b.getName());
            }
        });

        File stagingBase = new File(appFiles, "modsync-transaction");
        if (stagingBase.exists()) deleteTree(stagingBase);
        if (!stagingBase.mkdirs()) throw new Exception("无法创建临时同步目录。");

        Map<String, String> current = new HashMap<String, String>();
        Map<String, File> stagedRoots = new HashMap<String, File>();
        Map<String, String> sourceDigests = new HashMap<String, String>();
        Set<String> desiredRoots = new HashSet<String>();
        int changed = 0;

        try {
            int index = 0;
            for (File zip : archives) {
                String digest = sha256(zip);
                File staging = new File(stagingBase, "extract-" + (index++));
                if (!staging.mkdirs()) throw new Exception("无法创建临时解压目录。");
                String root = unzipOneRoot(zip, staging);
                if (!isSafeModDirectoryName(root)) {
                    throw new Exception(zip.getName() + " 的顶层 MOD 文件夹名称无效。");
                }
                File extracted = new File(staging, root);
                if (!extracted.isDirectory()) {
                    throw new Exception(zip.getName() + " 中未找到顶层 MOD 文件夹。");
                }
                if (!desiredRoots.add(root)) {
                    throw new Exception("多个 ZIP 包含同名 MOD 文件夹：" + root
                        + "。请确保一个 MOD 目录只由一个 ZIP 管理，避免来源冲突。");
                }
                current.put(zip.getName(), root);
                sourceDigests.put(zip.getName(), digest);
                stagedRoots.put(root, extracted);
            }

            List<File> backups = new ArrayList<File>();
            List<File> installed = new ArrayList<File>();
            List<File> removed = new ArrayList<File>();
            try {
                for (File zip : archives) {
                    String zipName = zip.getName();
                    String root = current.get(zipName);
                    File destination = new File(mods, root);
                    String wantedTree = treeSha256(stagedRoots.get(root));
                    String oldTree = prefs.getString("managed:tree:" + root, "");
                    boolean sourceChanged = !sourceDigests.get(zipName)
                        .equals(prefs.getString("zip:" + zipName, ""));
                    boolean destinationHealthy = destination.isDirectory()
                        && wantedTree.equals(treeSha256(destination));
                    if (!sourceChanged && destinationHealthy && wantedTree.equals(oldTree)) {
                        continue;
                    }

                    File backup = new File(stagingBase, "backup-" + root);
                    if (destination.exists()) {
                        if (!destination.renameTo(backup)) {
                            throw new Exception("无法暂存旧 MOD 目录：" + root);
                        }
                        backups.add(backup);
                    }
                    if (!stagedRoots.get(root).renameTo(destination)) {
                        if (backup.exists()) backup.renameTo(destination);
                        throw new Exception("无法安装 MOD 目录：" + root);
                    }
                    installed.add(destination);
                    changed++;
                }

                for (Map.Entry<String, String> old : previous.entrySet()) {
                    String oldRoot = old.getValue();
                    if (desiredRoots.contains(oldRoot)) continue;
                    if (!isSafeModDirectoryName(oldRoot)) {
                        throw new Exception("历史 MOD 管理记录包含无效目录名，已停止卸载以保护文件。");
                    }
                    File destination = new File(mods, oldRoot);
                    if (destination.exists()) {
                        File backup = new File(stagingBase, "removed-" + oldRoot);
                        if (!destination.renameTo(backup)) {
                            throw new Exception("无法卸载已从来源目录删除的 MOD：" + oldRoot);
                        }
                        backups.add(backup);
                        removed.add(backup);
                        changed++;
                    }
                }

                android.content.SharedPreferences.Editor editor = prefs.edit();
                for (String key : prefs.getAll().keySet()) {
                    if (key.startsWith("managed:zip:") || key.startsWith("managed:tree:")) {
                        editor.remove(key);
                    }
                }
                for (File zip : archives) {
                    String root = current.get(zip.getName());
                    editor.putString("managed:zip:" + zip.getName(), root);
                    editor.putString("managed:tree:" + root, treeSha256(new File(mods, root)));
                    editor.putString("zip:" + zip.getName(), sourceDigests.get(zip.getName()));
                }
                if (!editor.commit()) throw new Exception("无法保存 MOD 同步状态，已回滚本次文件操作。");

                deleteTree(stagingBase);
                return changed > 0 ? "UPDATED:" + changed : "UNCHANGED";
            } catch (Exception failure) {
                for (File destination : installed) deleteTree(destination);
                for (int i = backups.size() - 1; i >= 0; i--) {
                    File backup = backups.get(i);
                    if (backup.exists()) {
                        String name = backup.getName();
                        String root = name.startsWith("backup-") ? name.substring(7)
                            : name.startsWith("removed-") ? name.substring(8) : "";
                        if (root.length() > 0) backup.renameTo(new File(mods, root));
                    }
                }
                throw failure;
            }
        } finally {
            deleteTree(stagingBase);
        }
    }

    private static boolean isSafeModDirectoryName(String name) {
        return name != null && name.length() > 0 && !".".equals(name) && !"..".equals(name)
            && name.indexOf('/') < 0 && name.indexOf('\\\\') < 0
            && name.indexOf(':') < 0 && name.indexOf('\\0') < 0;
    }

    private static String treeSha256(File root) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        updateTreeDigest(root, root, digest);
        return toHex(digest.digest());
    }

    private static void updateTreeDigest(File root, File current, MessageDigest digest) throws Exception {
        if (current.isDirectory()) {
            File[] children = current.listFiles();
            if (children == null) throw new Exception("无法校验 MOD 目录：" + current);
            Arrays.sort(children, new Comparator<File>() {
                @Override public int compare(File a, File b) {
                    return a.getName().compareTo(b.getName());
                }
            });
            for (File child : children) updateTreeDigest(root, child, digest);
        } else if (current.isFile()) {
            String relative = root.toURI().relativize(current.toURI()).getPath();
            digest.update(relative.getBytes("UTF-8"));
            InputStream in = new BufferedInputStream(new FileInputStream(current));
            try {
                byte[] buffer = new byte[32768];
                int n;
                while ((n = in.read(buffer)) != -1) digest.update(buffer, 0, n);
            } finally {
                in.close();
            }
        } else {
            throw new Exception("MOD 目录中存在无法识别的文件类型：" + current);
        }
    }

    private static String toHex(byte[] bytes) {
        StringBuilder value = new StringBuilder();
        for (byte b : bytes) value.append(String.format(Locale.US, "%02x", b & 0xff));
        return value.toString();
    }

    private static String unzipOneRoot(File zip, File staging) throws Exception {
        ZipInputStream in = new ZipInputStream(new BufferedInputStream(new FileInputStream(zip)));
        String root = null;
        long total = 0;
        byte[] buffer = new byte[32768];
        Set<String> seen = new HashSet<String>();
        try {
            ZipEntry entry;
            while ((entry = in.getNextEntry()) != null) {
                String name = entry.getName().replace('\\\\', '/');
                if (name.length() == 0 || name.startsWith("/") || name.indexOf(':') >= 0
                        || name.indexOf('\\0') >= 0) {
                    throw new Exception("ZIP 含有不安全路径：" + name);
                }
                String[] parts = name.split("/");
                if (parts.length == 0 || !isSafeModDirectoryName(parts[0])) {
                    throw new Exception("ZIP 顶层目录无效：" + name);
                }
                for (String part : parts) {
                    if (part.length() == 0 || ".".equals(part) || "..".equals(part)) {
                        throw new Exception("ZIP 含有不安全路径：" + name);
                    }
                }
                if (root == null) root = parts[0];
                if (!root.equals(parts[0])) {
                    throw new Exception("一个 ZIP 中必须只有一个顶层 MOD 文件夹。");
                }
                if (!seen.add(name)) throw new Exception("ZIP 中存在重复路径：" + name);
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
        return toHex(digest.digest());
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
