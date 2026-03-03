const { execSync } = require('child_process');

function test() {
    try {
        const cmd = `npx firecrawl search "site:last.fm quran reciter Ahmed ibn Ali al-Ajmy" --limit 1 --json --scrape`;
        console.log(`Running: ${cmd}`);
        let output = execSync(cmd, { encoding: 'utf-8', stdio: 'pipe' });
        const result = JSON.parse(output);

        if (result.success && result.data && result.data.data && result.data.data.length > 0) {
            const html = result.data.data[0].html || result.data.data[0].markdown || result.data.data[0].content;
            console.log('Got content length:', html?.length);

            // last.fm uses: https://lastfm.freetls.fastly.net/i/u/300x300/... or 500x500 or avatar170s
            const urlMatch = html.match(/https:\/\/lastfm\.freetls\.fastly\.net\/i\/u\/(?:300x300|500x500|avatar170s)\/[a-f0-9]+\.(?:png|jpg|jpeg)/i);
            if (urlMatch) {
                console.log('Extracted URL:', urlMatch[0]);
            } else {
                console.log('No URL matched in content.');

                // Let's print a sample to see what images are there
                const anyImage = html.match(/https:\/\/[^"'\s]+\.(?:png|jpg|jpeg)/gi);
                console.log('Some images found:', anyImage ? anyImage.slice(0, 5) : 'None');
            }
        } else {
            console.log('Search failed or returned no results.');
        }
    } catch (e) {
        console.error(e.message);
    }
}

test();
