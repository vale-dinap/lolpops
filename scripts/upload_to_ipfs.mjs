import fs from 'fs'
import { NFTStorage, File, Blob } from 'nft.storage'

const basePath = "C:\\Users\\valer\\Desktop\\LOLPOPS\\LOLPOPS"
const endpoint = 'https://api.nft.storage' // the default
const token = '' // your API key from https://nft.storage/manage

async function store(basePath, id) {
    let storage = new NFTStorage({ endpoint, token })
    let data = await fs.promises.readFile(basePath+"\\IMG\\"+id+".png")
    let cid = await storage.storeBlob(new Blob([data]))
    console.log({ cid })
    let status = await storage.status(cid)
    console.log(status)
    return cid;
  }

async function setURI(basePath, id, cid) {
    let jsonFile = basePath+"\\JSON\\"+id+".json"
    fs.readFile(jsonFile, 'utf8', (error, data) => {
        if(error){
           console.log(error);
           return;
        }
        let jsonData=JSON.parse(data);
        jsonData.image = "https://ipfs.io/ipfs/"+cid;
        let stringData = JSON.stringify(jsonData, null, 4);
        fs.writeFile(jsonFile, stringData, (err) => {
            if (err) {
                throw err;
            }
            //console.log("JSON data is saved.");
        });
    })
}

async function uploadAll(base_path, iterations){
    for(let i=1;i<=iterations;i++){
        console.log("Working on image "+i+" of "+iterations+", "+Number(i)/Number(iterations)*100+"% completed")
        let cid = await store(base_path, i);
        setURI(base_path, i, cid);
    }
}

uploadAll(basePath, 10000)