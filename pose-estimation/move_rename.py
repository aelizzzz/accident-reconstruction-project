import shutil
import os
import sys

dr = sys.argv[1]
print("Processing smplx meshes at:" + dr)

for root, dirs, files in os.walk(dr):
    for file in files:
        if file == "000.obj":
            spl = root.split("/")
            newname = spl[-1]
            print("Renaming smplx file: " + newname)
            sup = ("/").join(spl[:-1])
            shutil.move(root+"/"+file, sup+"/"+newname+".obj")
            shutil.rmtree(root)