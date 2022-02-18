### This uses sha256 to generate the hash of each file ###
import hashlib, os, csv

#files_folder = "C:\\Users\\valer\\Desktop\\RENDER\\RENDER\\"
files_folder = "C:\\Users\\valer\\Desktop\\LOLPOPS\\LOLPOPS\\JSON\\"
dest_folder = "C:\\Users\\valer\\Desktop\\LOLPOPS\\LOLPOPS\\HASH\\"

def hashString(stringToHash):
    hash=hashlib.sha256()
    hash.update(stringToHash.encode("UTF-8"))
    return hash.hexdigest()

def sha256(fname):
    hash_sha256 = hashlib.sha256()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_sha256.update(chunk)
    return hash_sha256.hexdigest()

def hash_all(folder, fileExt, iterations):
    #files=sorted(os.listdir(folder))
    hashes = {}
    for i in range(1, iterations+1, 1):
        file = folder+str(i)+"."+fileExt
        #print("working on file "+file)
        hash = sha256(file)
        #print(hash)
        hashes.update({i:hash})
    return hashes

def hashAll_and_save(folder, fileExt, dest_folder, iterations):
    hashesDict=hash_all(folder, fileExt, iterations)
    ### CSV ###
    with open(dest_folder+fileExt+"_hash.csv", mode='w') as csv_file:
        data = csv.writer(csv_file, dialect='excel', delimiter=';', quotechar='"', lineterminator="\n")
        data.writerow(["id", "hash (sha256)"])
        for i in hashesDict:
            data.writerow([i, hashesDict[i]])
    ### TXT (one hash per line) ###
    with open(dest_folder+fileExt+"_hash.txt", mode='w') as txt_file:
        data_txt = ""
        for j in hashesDict:
            if j>1:
                data_txt+="\n"
            data_txt+=hashesDict[j]
        txt_file.write(data_txt)
    ### get concatenated hashes ###
    hashes_concat = ""
    for k in hashesDict:
        hashes_concat+=hashesDict[k]
    ### TXT (concatenated hashes) ###
    with open(dest_folder+fileExt+"_hash_concat.txt", mode='w') as concat_txt_file:
        concat_txt_file.write(hashes_concat)
    ### TXT (hash of all concatenated hashes) ###
    with open(dest_folder+fileExt+"_hash_of_hashes.txt", mode='w') as hash_of_hashes_txt_file:
        hash_of_hashes_txt_file.write(hashString(hashes_concat))

def hashListString(list):
    concat=list.replace("\n", "")
    #print(concat)
    return hashString(concat)

def getListFromTxtFile(file):
    with open(file, "r") as f:
        return f.read()

#cidList = getListFromTxtFile(dest_folder+"png_cid_list.txt")

#cidListHash = hashListString(cidList)
#print("CID list hash is: "+cidListHash)

#hashAll_and_save(files_folder, "png", dest_folder, 10000)
#hashAll_and_save(files_folder, "json", dest_folder, 10000)