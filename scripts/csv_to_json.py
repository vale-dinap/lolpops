### This helps extracting from the LOLPOPS csv a sequence of json files containing the attributes of each NFT ###

import json
import csv

csv_file = "C:\\Users\\valer\\Desktop\\LOLPOPS\\final_lolpops_SHUFFLE.csv"
dest_folder = "C:\\Users\\valer\\Desktop\\LOLPOPS\\LOLPOPS\\JSON_ATTRIBUTES"
verbose = False

def fetchAttributes(csv_file):
    with open(csv_file, newline='', encoding='utf-8') as open_file:
        data={}
        iter=0
        header=[]
        reader = csv.reader(open_file, dialect='excel')
        for row in reader:
            if iter==0:
                header = row[0].replace("\ufeffid", "id").split(";")
            else:
                rowDict=[]
                for x in range(0, len(header), 1):
                    if x==0:
                        pass
                    else:
                        rowDict.append({"trait_type":header[x].capitalize(),"value":noneEval( row[0].replace(" ", "").split(";")[x].capitalize() ) })
                data.update({iter:{"attributes": rowDict}})
            iter+=1
        #print(header)
        #print(data)
    return data

def noneEval(in_string):
    if in_string == "None":
        return None
    else:
        return in_string

def writeJson(formatted_dict, dest_file):
    data_to_write = json.dumps(formatted_dict)
    with open(dest_file, 'w') as json_file:
        json.dump(formatted_dict, json_file, indent=4, sort_keys=True)

def makeJson(csv_file, dest_folder):
    data = fetchAttributes(csv_file)
    for item in data:
        dest_file = dest_folder+"\\"+str(item)+".json"
        writeJson(data[item], dest_file)
        if verbose:
            print("Written: "+str(data[item])+"\nto file: "+dest_file)

makeJson(csv_file, dest_folder)