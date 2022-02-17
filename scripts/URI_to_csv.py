### Fetch URIs from NFT metadata json files, store in a cvs column ###

import json, csv

dest_csv_file = "C:\\Users\\valer\\Desktop\\LOLPOPS\\lolpops_URIs.csv"
json_folder = "C:\\Users\\valer\\Desktop\\LOLPOPS\\LOLPOPS\\JSON"

def getURIfromJson(file):
    with open(file) as json_file:
        data = json.load(json_file)
        URI = data["image"]
        return URI

def removeHttp(url):
    return url.split("ipfs/")[-1]

def extract_URI_to_csv(json_folder, dest_csv_file, iterations):
    with open(dest_csv_file, mode='w') as csv_file:
        data = csv.writer(csv_file, dialect='excel', delimiter=';', quotechar='"', lineterminator="\n")
        data.writerow(["id", "URI", "View path"])
        for i in range(1, iterations+1, 1):
            source_file = json_folder+"\\"+str(i)+".json"
            URI = getURIfromJson(source_file).replace(" ", "").replace("\n", "")
            #print(URI)
            data.writerow([str(i), removeHttp(URI), URI])

extract_URI_to_csv(json_folder, dest_csv_file, 5)