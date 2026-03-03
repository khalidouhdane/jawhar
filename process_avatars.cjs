/**
 * Smart Face-Crop & Optimize Reciter Avatars
 * 
 * Uses smartcrop to detect face/attention areas, then crops to square
 * centered on the face, and optimizes to consistent size + quality.
 */
const sharp = require('sharp');
const smartcrop = require('smartcrop-sharp');
const fs = require('fs');
const path = require('path');

const INPUT_DIR = path.join(__dirname, 'assets', 'images', 'reciters');
const BACKUP_DIR = path.join(__dirname, 'assets', 'images', 'reciters_backup');
const TARGET_SIZE = 400; // 400x400 px output
const JPEG_QUALITY = 85; // Good balance between quality and size

async function processImage(filePath) {
    const filename = path.basename(filePath);

    try {
        const meta = await sharp(filePath).metadata();
        const { width, height } = meta;

        // Determine the crop size (largest square that fits)
        const cropSize = Math.min(width, height);

        // Use smartcrop to find the best crop region (focuses on faces/attention)
        const result = await smartcrop.crop(filePath, { width: cropSize, height: cropSize });
        const crop = result.topCrop;

        // Extract the smart-cropped region, then resize and optimize
        const outputBuffer = await sharp(filePath)
            .extract({
                left: crop.x,
                top: crop.y,
                width: crop.width,
                height: crop.height
            })
            .resize(TARGET_SIZE, TARGET_SIZE, {
                kernel: sharp.kernel.lanczos3,
                fit: 'cover'
            })
            .jpeg({ quality: JPEG_QUALITY, mozjpeg: true })
            .toBuffer();

        // Write back
        fs.writeFileSync(filePath, outputBuffer);

        const newSize = outputBuffer.length;
        const oldSize = fs.statSync(path.join(BACKUP_DIR, filename)).size;
        const savings = ((1 - newSize / oldSize) * 100).toFixed(0);

        console.log(
            `  ✅ ${filename.padEnd(10)} ${width}x${height} → ${TARGET_SIZE}x${TARGET_SIZE}  ` +
            `${(oldSize / 1024).toFixed(0)}KB → ${(newSize / 1024).toFixed(0)}KB  (${savings}% ${savings > 0 ? 'smaller' : 'larger'})`
        );
    } catch (err) {
        console.error(`  ❌ ${filename}: ${err.message}`);
    }
}

async function main() {
    // Create backup
    if (!fs.existsSync(BACKUP_DIR)) {
        fs.mkdirSync(BACKUP_DIR, { recursive: true });
        console.log('📁 Created backup directory');
    }

    const files = fs.readdirSync(INPUT_DIR)
        .filter(f => f.endsWith('.jpg'))
        .sort((a, b) => parseInt(a) - parseInt(b));

    console.log(`\n🖼️  Processing ${files.length} reciter images...\n`);

    // Backup originals
    for (const f of files) {
        const src = path.join(INPUT_DIR, f);
        const dest = path.join(BACKUP_DIR, f);
        if (!fs.existsSync(dest)) {
            fs.copyFileSync(src, dest);
        }
    }
    console.log('💾 Originals backed up to reciters_backup/\n');

    // Process each image
    for (const f of files) {
        await processImage(path.join(INPUT_DIR, f));
    }

    // Summary
    console.log('\n📊 Summary:');
    let totalOld = 0, totalNew = 0;
    for (const f of files) {
        totalOld += fs.statSync(path.join(BACKUP_DIR, f)).size;
        totalNew += fs.statSync(path.join(INPUT_DIR, f)).size;
    }
    console.log(`   Total: ${(totalOld / 1024).toFixed(0)}KB → ${(totalNew / 1024).toFixed(0)}KB (${((1 - totalNew / totalOld) * 100).toFixed(0)}% savings)`);
    console.log('   All images: ' + TARGET_SIZE + 'x' + TARGET_SIZE + ' JPEG @ quality ' + JPEG_QUALITY);
    console.log('\n✨ Done! Originals are safe in assets/images/reciters_backup/');
}

main().catch(console.error);
