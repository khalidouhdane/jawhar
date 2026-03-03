const fs = require('fs');
const https = require('https');
const path = require('path');

const ASSETS_DIR = path.join(__dirname, 'assets', 'images', 'reciters');

// Reliable direct image links for the top 5
const reciters = [
    { id: 7, url: 'https://lastfm.freetls.fastly.net/i/u/300x300/e9dc2b7c6cb84693ae2c4cdd88d3d928.png' }, // Mishary
    { id: 3, url: 'https://lastfm.freetls.fastly.net/i/u/300x300/40e340dcd5204481977dcfd6e0339ab4.jpg' }, // Husary
    { id: 9, url: 'https://lastfm.freetls.fastly.net/i/u/300x300/7a73155734894df0bc044dbbd0aa8b10.jpg' }, // Minshawi
    { id: 2, url: 'https://lastfm.freetls.fastly.net/i/u/300x300/8d8a57e3240e4ab7bbb118a80ef0a8bd.jpg' }, // AbdulBaset
    { id: 97, url: 'https://lastfm.freetls.fastly.net/i/u/300x300/47fdf0abcb2cce090de3d4c6db24dece.jpg' } // Yasser
];

async function downloadImage(url, dest) {
    return new Promise((resolve, reject) => {
        https.get(url, { headers: { 'User-Agent': 'curl/7.81.0' } }, (response) => {
            if (response.statusCode === 200) {
                const file = fs.createWriteStream(dest);
                response.pipe(file);
                file.on('finish', () => file.close(resolve));
            } else {
                reject(new Error(`StatusCode: ${response.statusCode}`));
            }
        }).on('error', reject);
    });
}

async function run() {
    for (const r of reciters) {
        const dest = path.join(ASSETS_DIR, `${r.id}.jpg`);
        try {
            if (fs.existsSync(dest)) { fs.unlinkSync(dest); }
            await downloadImage(r.url, dest);
            console.log(`Success: ${r.id}.jpg downloaded`);
        } catch (e) {
            console.error(`Error for ${r.id}:`, e.message);
        }
    }
}
run();
