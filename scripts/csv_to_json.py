### This helps extracting from the LOLPOPS csv a sequence of json files containing the attributes of each NFT ###

import json, csv

csv_file = "C:\\Users\\valer\\Desktop\\LOLPOPS\\final_lolpops_SHUFFLE.csv"
dest_folder = "C:\\Users\\valer\\Desktop\\LOLPOPS\\LOLPOPS\\JSON"
verbose = False

nft_data_name = "Lolpop"
nft_data_description = "LOLPOPs is a collection of 10,000 procedurally generated NFTs that live in perpetuity on the Ethereum Blockchain. LOLPOPs owners will have early and exclusive access to future NFT claims, allowlists, special raffles, community giveaways, POPVERSE games and more. Let's get it poppin' in here! Visit [www.lolpopsnft.art](https://www.lolpopsnft.art/) to learn more!"
nft_data_image = "this will be replaced by the IPFS path"

def formatMetadata(id, name, description, image, attributes):
    metadata={"name":name+" #"+str(id), "description":description, "image":image, "attributes":attributes}
    return metadata

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
                        value = row[0].replace(" ", "").split(";")[x].capitalize()
                        if(value != "None"):
                            rowDict.append({"trait_type":header[x].capitalize(),"value":noneEval( value ) })
                data.update({ iter:formatMetadata(iter, nft_data_name, nft_data_description, nft_data_image, rowDict) })
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
    with open(dest_file, 'w') as json_file:
        json.dump(formatted_dict, json_file, indent=4, sort_keys=False)

def makeJson(csv_file, dest_folder):
    data = fetchAttributes(csv_file)
    for item in data:
        dest_file = dest_folder+"\\"+str(item)+".json"
        writeJson(data[item], dest_file)
        if verbose:
            print("Written: "+str(data[item])+"\nto file: "+dest_file)

makeJson(csv_file, dest_folder)