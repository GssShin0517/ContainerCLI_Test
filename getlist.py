import os

# 設定資料夾路徑
folder_path = r"C:\Users\fred_lu\work\Cx\ContainerCLI_Test\reports"

# 只抓檔案（不包含資料夾）
all_files = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f))]

# 輸出到 txt
with open("file_list.txt", "w", encoding="utf-8") as f:
    for file in all_files:
        f.write(file + "\n")

print("已完成，檔名存到 file_list.txt")
