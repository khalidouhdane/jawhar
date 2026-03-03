const fs = require('fs');
const https = require('https');
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

const CLIENT_ID = '879421dc-68cb-4a1d-a500-c060d10478e6';
const CLIENT_SECRET = 'cKEt~daJ4tgXiJ1td0t4JwBB_z';
const ASSETS_DIR = path.join(__dirname, 'assets', 'images', 'reciters');
const SCHEMA_FILE = path.join(__dirname, 'schema.json');

async function getQuranToken() {
    return new Promise((resolve, reject) => {
        const authStr = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');
        const req = https.request('https://oauth2.quran.foundation/oauth2/token', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Authorization': `Basic ${authStr}`
            }
        }, res => {
            let data = '';
            res.on('data', d => data += d);
            res.on('end', () => res.statusCode === 200 ? resolve(JSON.parse(data).access_token) : reject(new Error('Auth failed')));
        });
        req.write('grant_type=client_credentials&scope=content');
        req.end();
    });
}

async function getReciters(token) {
    return new Promise((resolve, reject) => {
        https.get('https://apis.quran.foundation/content/api/v4/resources/chapter_reciters', {
            headers: { 'x-auth-token': token, 'x-client-id': CLIENT_ID }
        }, res => {
            let data = '';
            res.on('data', d => data += d);
            res.on('end', () => res.statusCode === 200 ? resolve(JSON.parse(data).reciters) : reject(new Error('Fetch failed')));
        });
    });
}

async function downloadImage(url, dest) {
    return new Promise((resolve, reject) => {
        https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, res => {
            if (res.statusCode === 301 || res.statusCode === 302) {
                return downloadImage(res.headers.location, dest).then(resolve).catch(reject);
            }
            if (res.statusCode === 200) {
                const file = fs.createWriteStream(dest);
                res.pipe(file);
                file.on('finish', () => file.close(resolve));
            } else {
                reject(new Error(`Download failed with status ${res.statusCode}`));
            }
        }).on('error', reject);
    });
}

async function processReciter(r) {
    const dest = path.join(ASSETS_DIR, `${r.id}.jpg`);
    if (fs.existsSync(dest)) {
        console.log(`Skipping ${r.name}, already exists.`);
        return;
    }

    console.log(`[${r.name}] Spawning Firecrawl Agent...`);
    try {
        const prompt = `Find a high quality portrait photo URL of quran reciter ${r.name}. Return the direct image URL.`;
        const cmd = `npx firecrawl agent "${prompt}" --schema-file "${SCHEMA_FILE}" --wait --json`;

        // Execute Firecrawl CLI agent (this will take 30-90s each)
        const { stdout } = await execPromise(cmd, { encoding: 'utf-8' });

        const lines = stdout.split('\\n');
        let jsonStr = lines.find(l => l.startsWith('{'));
        if (!jsonStr) jsonStr = stdout.substring(stdout.indexOf('{'));

        const result = JSON.parse(jsonStr);
        if (result.success && result.data && result.data.imageUrl) {
            console.log(`[${r.name}] Found URL: ${result.data.imageUrl}`);
            await downloadImage(result.data.imageUrl, dest);
            console.log(`[${r.name}] Successfully saved ${r.id}.jpg`);
        } else {
            console.log(`[${r.name}] Agent failed to find a valid URL.`);
        }
    } catch (e) {
        console.error(`[${r.name}] Error:`, e.message);
    }
}

async function run() {
    try {
        const token = await getQuranToken();
        const reciters = await getReciters(token);

        const targetIds = [7, 3, 9, 2, 97];
        const filteredReciters = reciters.filter(r => targetIds.includes(r.id));
        console.log(`Targeting ${filteredReciters.length} specific reciters...`);

        // Process in batches of 5 to avoid overloading terminal/OS process limits
        const BATCH_SIZE = 5;
        for (let i = 0; i < filteredReciters.length; i += BATCH_SIZE) {
            const batch = filteredReciters.slice(i, i + BATCH_SIZE);
            await Promise.all(batch.map(r => processReciter(r)));
        }
        console.log('Finished all agents!');
    } catch (err) {
        console.error('Script failed:', err.message);
    }
}

run();
