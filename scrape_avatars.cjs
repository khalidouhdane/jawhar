const fs = require('fs');
const http = require('http');
const https = require('https');
const path = require('path');

const CLIENT_ID = '879421dc-68cb-4a1d-a500-c060d10478e6';
const CLIENT_SECRET = 'cKEt~daJ4tgXiJ1td0t4JwBB_z';
const AUTH_URL = 'https://oauth2.quran.foundation/oauth2/token';
const API_URL = 'https://apis.quran.foundation/content/api/v4';

const ASSETS_DIR = path.join(__dirname, 'assets', 'images', 'reciters');

if (!fs.existsSync(ASSETS_DIR)) {
    fs.mkdirSync(ASSETS_DIR, { recursive: true });
}

async function fetchToken() {
    return new Promise((resolve) => {
        const data = `grant_type=client_credentials&scope=content`;
        const authHeader = 'Basic ' + Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');

        const req = https.request(AUTH_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(data),
                'Authorization': authHeader
            }
        }, (res) => {
            let body = '';
            res.on('data', d => body += d);
            res.on('end', () => resolve(JSON.parse(body).access_token));
        });
        req.write(data);
        req.end();
    });
}

function fetchJson(url, headers = {}) {
    return new Promise((resolve, reject) => {
        const protocol = url.startsWith('https') ? https : http;
        const req = protocol.get(url, { headers }, (res) => {
            let body = '';
            res.on('data', d => body += d);
            res.on('end', () => resolve(JSON.parse(body)));
        });
        req.on('error', reject);
    });
}

function normalizeName(name) {
    return name.toLowerCase().replace(/[^a-z0-9]/g, '');
}

async function downloadImage(url, dest) {
    return new Promise((resolve, reject) => {
        const protocol = url.startsWith('https') ? https : http;
        const file = fs.createWriteStream(dest);
        protocol.get(url, (response) => {
            if (response.statusCode === 200) {
                response.pipe(file);
                file.on('finish', () => {
                    file.close(resolve);
                });
            } else {
                file.close();
                fs.unlink(dest, () => resolve()); // Delete empty file
            }
        }).on('error', (err) => {
            fs.unlink(dest, () => resolve());
        });
    });
}

async function run() {
    console.log('1. Fetching Quran.com token...');
    const token = await fetchToken();

    console.log('2. Fetching Quran.com reciters...');
    const qcRes = await fetchJson(`${API_URL}/resources/chapter_reciters`, {
        'x-auth-token': token,
        'x-client-id': CLIENT_ID
    });
    const quranReciters = qcRes.reciters;
    console.log(`Found ${quranReciters.length} reciters.`);

    console.log('3. Fetching MP3Quran API reciters...');
    const mp3Res = await fetchJson('https://mp3quran.net/api/v3/reciters?language=eng');
    const mp3Reciters = mp3Res.reciters;

    console.log('4. Matching and downloading images...');
    for (const qcReciter of quranReciters) {
        const normQcName = normalizeName(qcReciter.name);

        // Manual overrides for tricky names
        let matchedSrc = mp3Reciters.find(m => {
            const normMp3Name = normalizeName(m.name);
            return normMp3Name.includes(normQcName) || normQcName.includes(normMp3Name);
        });

        if (qcReciter.name.includes("Mishari")) {
            matchedSrc = mp3Reciters.find(m => normalizeName(m.name).includes('mishary'));
        } else if (qcReciter.name.includes("AbdulBaset")) {
            matchedSrc = mp3Reciters.find(m => m.id === 13); // Abdulbasit
        } else if (qcReciter.name.includes("Husary")) {
            matchedSrc = mp3Reciters.find(m => m.id === 35); // Husary
        } else if (qcReciter.name.includes("Minshawi")) {
            matchedSrc = mp3Reciters.find(m => m.id === 41); // Minshawi
        } else if (qcReciter.name.includes("Banna")) {
            matchedSrc = mp3Reciters.find(m => m.id === 115); // Banna
        }

        if (matchedSrc) {
            if (matchedSrc.moshaf && matchedSrc.moshaf.length > 0) {
                // Moshaf array format or single object. Usually an array.
                // Let's check MP3Quran's image endpoint format
            }
            // MP3 Quran's image URL format usually is not directly in the reciters list like that but we can try other sources or Quran.com web
        }
    }
}
run();
