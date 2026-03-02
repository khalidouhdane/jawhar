import fs from 'fs';
import path from 'path';

const CLIENT_ID = '879421dc-68cb-4a1d-a500-c060d10478e6';
const CLIENT_SECRET = 'cKEt~daJ4tgXiJ1td0t4JwBB_z';
const AUTH_URL = 'https://oauth2.quran.foundation/oauth2/token';
const API_URL = 'https://apis.quran.foundation/content/api/v4';

const __dirname = path.resolve();
const ASSETS_DIR = path.join(__dirname, 'assets', 'images', 'reciters');

if (!fs.existsSync(ASSETS_DIR)) {
    fs.mkdirSync(ASSETS_DIR, { recursive: true });
}

function normalizeName(name) {
    return name.toLowerCase().replace(/[^a-z0-9]/g, '');
}

async function run() {
    try {
        console.log('1. Fetching Quran.com auth token...');
        const authRes = await fetch(AUTH_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Authorization': 'Basic ' + Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64')
            },
            body: 'grant_type=client_credentials&scope=content'
        });
        const authData = await authRes.json();
        const token = authData.access_token;

        console.log('2. Fetching Quran.com reciters...');
        const qcRes = await fetch(`${API_URL}/resources/chapter_reciters`, {
            headers: { 'x-auth-token': token, 'x-client-id': CLIENT_ID }
        });
        const { reciters: quranReciters } = await qcRes.json();
        console.log(`Found ${quranReciters.length} reciters. Processing...`);

        // Let's also check MP3Quran
        console.log('3. Fetching MP3Quran API...');
        const mp3Res = await fetch('https://mp3quran.net/api/v3/reciters?language=eng');
        const mp3Data = await mp3Res.json();
        const mp3Reciters = mp3Data.reciters || [];

        // Aladhan API for reciters as well, just in case
        // http://api.aladhan.com/v1/edition?format=audio&language=ar

        // Mapping manual image URLs if we know them
        // Quran.com sometimes has them at https://quran.com/images/reciters/{id}/profile.png
        // Qurancdn might have them at https://audio.qurancdn.com/reciters/{id}/profile.png

        let downloadedCount = 0;

        for (const qcReciter of quranReciters) {
            const destPath = path.join(ASSETS_DIR, `${qcReciter.id}.jpg`);
            let imgUrl = null;

            // Check MP3Quran mapping
            const normQcName = normalizeName(qcReciter.name);
            let matchedMp3 = mp3Reciters.find(m => {
                const normMp3Name = normalizeName(m.name);
                return normMp3Name.includes(normQcName) || normQcName.includes(normMp3Name);
            });
            // some hardcoded
            if (qcReciter.name.includes("Mishari")) matchedMp3 = mp3Reciters.find(m => m.id === 4);
            else if (qcReciter.name.includes("Husary")) matchedMp3 = mp3Reciters.find(m => m.id === 35);
            else if (qcReciter.name.includes("Minshawi")) matchedMp3 = mp3Reciters.find(m => m.id === 41);
            else if (qcReciter.name.includes("Dussary")) matchedMp3 = mp3Reciters.find(m => m.id === 135); // Yasser
            else if (qcReciter.name.includes("Tunaiji")) matchedMp3 = mp3Reciters.find(m => m.id === 51); // Khalifa
            else if (qcReciter.name.includes("Abdur-Rahman as-Sudais")) matchedMp3 = mp3Reciters.find(m => m.id === 37);
            else if (qcReciter.name.includes("Hani ar-Rifai")) matchedMp3 = mp3Reciters.find(m => m.id === 36);
            else if (qcReciter.name.includes("Abu Bakr al-Shatri")) matchedMp3 = mp3Reciters.find(m => m.id === 63);

            if (matchedMp3 && matchedMp3.moshaf && matchedMp3.moshaf.length > 0) {
                // Unfortunately mp3quran's new API doesn't include the 'image' property in the reciter object directly often, 
                // wait, let's look at what's in 'moshaf'
                // Let's just try to download from a known CDN or Google Search fallback, but that's hard.
            }

            // Let's just try to fetch from Quran.com's frontend assets: https://quran.com/images/reciters/{id}/profile.png
            // Actually they don't use this. The easiest way for now is just to provide an empty file if we don't know it, 
            // or print out the names so the user knows which ones exist. Let's see if we can get anything from mp3quran.
        }
    } catch (e) {
        console.error(e);
    }
}
run();
