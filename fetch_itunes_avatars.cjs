const fs = require('fs');
const https = require('https');
const path = require('path');

const ASSETS_DIR = path.join(__dirname, 'assets', 'images', 'reciters');

const reciters = [
    { id: 7, term: 'Mishari Alafasy' },
    { id: 3, term: 'Mahmoud Khalil Al-Hussary' },
    { id: 9, term: 'Mohamed Siddiq El-Minshawi' },
    { id: 2, term: 'Abdul Basit Abdus Samad' },
    { id: 97, term: 'Yasser Al Dosari' }
];

async function fetchJSON(url) {
    return new Promise((resolve, reject) => {
        https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => resolve(JSON.parse(data)));
        }).on('error', reject);
    });
}

function downloadImage(url, dest) {
    return new Promise((resolve, reject) => {
        https.get(url, (res) => {
            if (res.statusCode === 200) {
                const file = fs.createWriteStream(dest);
                res.pipe(file);
                file.on('finish', () => file.close(resolve));
            } else {
                reject(new Error(`Failed with status ${res.statusCode}`));
            }
        }).on('error', reject);
    });
}

async function run() {
    for (const r of reciters) {
        console.log(`Searching iTunes for ${r.term}...`);
        try {
            const searchUrl = `https://itunes.apple.com/search?term=${encodeURIComponent(r.term)}&entity=album&limit=1`;
            const data = await fetchJSON(searchUrl);
            if (data.results && data.results.length > 0) {
                // Get the high-res artwork URL (replace 100x100 with 600x600)
                let artworkUrl = data.results[0].artworkUrl100;
                artworkUrl = artworkUrl.replace('100x100', '600x600');

                const dest = path.join(ASSETS_DIR, `${r.id}.jpg`);
                console.log(`Downloading artwork for ${r.term}: ${artworkUrl}`);
                if (fs.existsSync(dest)) fs.unlinkSync(dest); // clear old one
                await downloadImage(artworkUrl, dest);
                console.log(`Success: saved to ${r.id}.jpg`);
            } else {
                console.log(`No results found for ${r.term}`);
            }
        } catch (e) {
            console.error(`Error for ${r.term}:`, e.message);
        }
    }
}

run();
