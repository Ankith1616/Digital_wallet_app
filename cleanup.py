import shutil
import os
import stat
import time

def force_delete(target_dir):
    print(f"Force deleting '{target_dir}'...")
    if not os.path.exists(target_dir):
        print(f"'{target_dir}' does not exist.")
        return

    def on_rm_error(func, path, exc_info):
        try:
            os.chmod(path, stat.S_IWRITE)
            func(path)
        except Exception as e:
            pass
            
    for attempt in range(5):
        try:
            shutil.rmtree(target_dir, onerror=on_rm_error)
            print(f"Successfully deleted '{target_dir}'.")
            return
        except Exception as e:
            time.sleep(1)
            
force_delete('build')
force_delete('.dart_tool')
force_delete('android/.gradle')
force_delete('android/app/build')
