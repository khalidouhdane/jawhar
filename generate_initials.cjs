const https = require('https');
const fs = require('fs');
const path = require('path');
const ASSETS = path.join(__dirname, 'assets', 'images', 'reciters');

const reciters = [
    { id: 7, url: 'https://api.dicebear.com/7.x/initials/png?seed=Mishary&backgroundColor=1e293b&textColor=ffffff&fontWeight=900' },
    { id: 3, url: 'https://api.dicebear.com/7.x/initials/png?seed=Husary&backgroundColor=0f766e&textColor=ffffff&fontWeight=900' },
    { id: 9, url: 'https://api.dicebear.com/7.x/initials/png?seed=Minshawi&backgroundColor=6d28d9&textColor=ffffff&fontWeight=900' },
    { id: 2, url: 'https://api.dicebear.com/7.x/initials/png?seed=AbdulBaset&backgroundColor=b45309&textColor=ffffff&fontWeight=900' },
    { id: 97, url: 'https://api.dicebear.com/7.x/initials/png?seed=Yasser&backgroundColor=334155&textColor=ffffff&fontWeight=900' }
];

reciters.forEach(r => {
    https.get(r.url, res => {
        const f = fs.createWriteStream(path.join(ASSETS, `${r.id}.jpg`));
        res.pipe(f);
    });
});
