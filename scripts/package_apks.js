const fs = require('fs');
const path = require('path');

function packageApks() {
  const rootDir = path.resolve(__dirname, '..');
  const apkDir = path.join(rootDir, 'build', 'app', 'outputs', 'flutter-apk');
  const distDir = path.join(rootDir, 'dist');

  if (!fs.existsSync(distDir)) {
    fs.mkdirSync(distDir, { recursive: true });
  }

  const mapping = [
    { src: 'app-arm64-v8a-release.apk', dest: 'PrismTV-arm64-v8a.apk' },
    { src: 'app-armeabi-v7a-release.apk', dest: 'PrismTV-armeabi-v7a.apk' },
    { src: 'app-x86_64-release.apk', dest: 'PrismTV-x86_64.apk' },
    { src: 'app-release.apk', dest: 'PrismTV-universal.apk' }
  ];

  console.log('\n==================================================');
  console.log('       PrismTV Standardized Android APKs          ');
  console.log('==================================================');

  let count = 0;
  for (const item of mapping) {
    const srcPath = path.join(apkDir, item.src);
    const destPath = path.join(distDir, item.dest);
    if (fs.existsSync(srcPath)) {
      fs.copyFileSync(srcPath, destPath);
      const stats = fs.statSync(destPath);
      console.log(`[OK] ${item.dest} (${(stats.size / 1024 / 1024).toFixed(2)} MB)`);
      count++;
    }
  }

  if (count === 0) {
    console.log('No release APKs found in build/app/outputs/flutter-apk/. Run "flutter build apk --release --split-per-abi" first.');
  } else {
    console.log(`\nSuccessfully packaged ${count} Android APK(s) to ${distDir}`);
  }
  console.log('==================================================\n');
}

packageApks();

