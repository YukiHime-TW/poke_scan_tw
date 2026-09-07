'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "6bb505596bebc3b1b9bc0dddb1844c17",
"assets/AssetManifest.bin.json": "7b813d83c12d0c7be6810c33f4e49dc2",
"assets/assets/icon.png": "b2adaa90c44e5b4000ced55f2d218ab6",
"assets/assets/index.json": "74027991477cad9a53dd825e29c3521a",
"assets/assets/sets/AC1a.json": "7cb65b5ef21eda19d2ac5ac62fb7090a",
"assets/assets/sets/AC1b.json": "acadc5fee8aee0f7b1b8d98304d3f3a2",
"assets/assets/sets/AC1D.json": "6045fd57d9adfaddbf15b1a1ea22a56f",
"assets/assets/sets/AC2a.json": "2ce8af2126a73b50d26258f79141da16",
"assets/assets/sets/AC2b.json": "11d62326d3e2f3542e231b3fecbf23b0",
"assets/assets/sets/AC2D.json": "b3c5ce87f21b87ff2269014aa3509cec",
"assets/assets/sets/AS5a.json": "1134277f0ed446cfa0bebab7c2ca97ef",
"assets/assets/sets/AS5b.json": "0e1c0a8f37e11439a5ea8c28f365b03c",
"assets/assets/sets/AS5D.json": "7d4e9126a3dfaece50a6fcb740b0319a",
"assets/assets/sets/AS6a.json": "4bde0fe9cfe98064fde4922aafbfe802",
"assets/assets/sets/AS6b.json": "e0b391d94e412bcccf5e4751f0daceb7",
"assets/assets/sets/AS6D.json": "2bfe64a79fd1da5183d5adc2677df435",
"assets/assets/sets/ENERGY.json": "4a6aacbd951f246d41d489710f449052",
"assets/assets/sets/M-P.json": "9ca809785bc4b7ba7fb4cc64c53c9f1f",
"assets/assets/sets/M1L.json": "3640e581ab517106087a4430fb322b12",
"assets/assets/sets/M1S.json": "135dc034d0bacb40f6dc9e1086513752",
"assets/assets/sets/M2.json": "529ba9b6395bc623b5332fb8dccee08a",
"assets/assets/sets/M2a.json": "dc02641b34e0167f2f888dca2712e4f1",
"assets/assets/sets/M3.json": "d61dcac1529557b7ef6ef5f0ce9e7db8",
"assets/assets/sets/M4.json": "0ee7a60c0fe098a21e88fd0e5b43f29f",
"assets/assets/sets/M5.json": "58eaf7212b2184986f93a56fa6a26ee2",
"assets/assets/sets/M6.json": "a6f57f6eef510a0616aec36c30e5dfee",
"assets/assets/sets/MBD.json": "e561d0bd21a580c0bc602eb862ff35cd",
"assets/assets/sets/MBG.json": "10d5371ee84fa299816f33f7736f8905",
"assets/assets/sets/MC.json": "a9dbbfe900e411adb3019888f324c72a",
"assets/assets/sets/MTH.json": "249263521dbe9944f0323e6c114b3833",
"assets/assets/sets/MTK.json": "f90758a4eb4062a35dfc66ecc031f083",
"assets/assets/sets/MTL.json": "a38de9e13da46552f6ea0610214b21e0",
"assets/assets/sets/MTS.json": "f718ff829c1a6728b5fb3ac6479a7eb6",
"assets/assets/sets/S-P.json": "5cc91fac093d794ce4f1d5cf76ff0afb",
"assets/assets/sets/S10a.json": "d73da17327a4b61b22bff444a1309600",
"assets/assets/sets/S10b.json": "e750b954c5e59da03159a82772ee89dc",
"assets/assets/sets/S10D.json": "77d9d7c0cf2aef54f4c26065b31963d0",
"assets/assets/sets/S10P.json": "072bf6ec2f613b47692d2d37d22c3711",
"assets/assets/sets/S11.json": "b1f9321da9ec423a631db81323a01083",
"assets/assets/sets/S11a.json": "2f7e9eb40b7ad9a64008ae033b5ed448",
"assets/assets/sets/S12.json": "43368176671f51c0376d0a7b35f376eb",
"assets/assets/sets/S12a.json": "c886a775969b2aa37777ab4100f29f8a",
"assets/assets/sets/S4.json": "a400fd44baeb48aae0bebc4c41fa63c0",
"assets/assets/sets/S4a.json": "1cf37e3f825ef9221035fd2169d86ce1",
"assets/assets/sets/S5a.json": "6ec8fbcbc2459c76b8aa8daf0249b6a3",
"assets/assets/sets/S5I.json": "74e2fe76e8376fad7c5b606fc6dda06a",
"assets/assets/sets/S5R.json": "05bc0c8e381ffaf23bab5e62eb637fdf",
"assets/assets/sets/S6a.json": "2236ffe306901cc04149b9f7e353cf5a",
"assets/assets/sets/S6H.json": "1e3eb58a5f51743d107a4add839bfd7e",
"assets/assets/sets/S6K.json": "3eade3e0d12f5552776c2dcdc3997a30",
"assets/assets/sets/S7D.json": "626f3adf407fc2a70b99442e5c40818d",
"assets/assets/sets/S7R.json": "82f719e76ab620217b946a3e613777fc",
"assets/assets/sets/S8.json": "a7c53bf37f2c9c6aa4d02fa7b1e6b7bf",
"assets/assets/sets/S8a.json": "22fa90f694edfabdb77401793a7b51b2",
"assets/assets/sets/S8b.json": "11c2c0ac4e72dd6fcaadc9009ed84737",
"assets/assets/sets/S9.json": "6d3c863eafc73ef0b99043107bf0d316",
"assets/assets/sets/S9a.json": "edd9b2e9a2ab232dcc1e2e9e1b71f3d2",
"assets/assets/sets/SC1a.json": "bbc7a247c7b1faacfc8ca9465de99afe",
"assets/assets/sets/SC1b.json": "ceb5dfb74e197c1df19b1ec21205991b",
"assets/assets/sets/SC1D.json": "d7fa1b1370d1b4cbe9a8cac1de1ddc9c",
"assets/assets/sets/SC2a.json": "ae5572662fd191f74f5e2e6e45e57ff6",
"assets/assets/sets/SC2b.json": "5464dcffa032783c2a6aafb8459a5d78",
"assets/assets/sets/SC2D.json": "57dff2105474c68535aa6eaa445f18b5",
"assets/assets/sets/SCA.json": "0fb10b44d3b0d42352fca0c05866c69a",
"assets/assets/sets/SCB.json": "179e9ee289e672d730a09db5ca8cea19",
"assets/assets/sets/SCC.json": "384e7ee474fd5d4e2ce9829ce6b65240",
"assets/assets/sets/SCD.json": "a6e19e7d5c131fa6906d2baa6a0caaca",
"assets/assets/sets/SDL.json": "ee903cccf2e5e89a2618861a1dc8327b",
"assets/assets/sets/SDM.json": "18bc69e1334063d01f4ee18a77d74efd",
"assets/assets/sets/SDP.json": "34ab476dcc68a1e4cdb66eb924950d5d",
"assets/assets/sets/SH.json": "cf5ca01ba5b59864ae9daac249f5d71e",
"assets/assets/sets/SI.json": "4f5be4bb76098705a76a16f8c89c4a06",
"assets/assets/sets/SJ.json": "5bf470fb9afa647df0164991567be874",
"assets/assets/sets/SK.json": "ae9bceed3dad84fbd1a0b98c5a7d2624",
"assets/assets/sets/SLD.json": "680f08b725e7901e172f50ffccb93fae",
"assets/assets/sets/SLL.json": "402bb7cf801ead1dd7279a8fbb85d4c6",
"assets/assets/sets/SM-P.json": "aaaece5cadf48ecda996456ae3d8e3b5",
"assets/assets/sets/SN.json": "032ade2c4fa33aab88b524eef776a278",
"assets/assets/sets/SO.json": "479d69a1f73e0249534ffbf3ff8e0cc2",
"assets/assets/sets/SP5.json": "e50af3ce7d13818cba47d86fe469d843",
"assets/assets/sets/SP6.json": "d7f3f679fda33623d06d60e49e012a59",
"assets/assets/sets/SPD.json": "4d38e8b1f30072f7e9390d2d2900ab42",
"assets/assets/sets/SPZ.json": "e32b5024f8f8fb6e1c1458384b06804c",
"assets/assets/sets/SV-P.json": "d05b267138b19458d4f8eb2d7ba6cfe3",
"assets/assets/sets/SV10.json": "e9dd653e4d8c83af073bb21d3af8e61d",
"assets/assets/sets/SV11B.json": "4be5adc7a0c8e6f2acb6cdf760479878",
"assets/assets/sets/SV11W.json": "ba3149fdac98a969329015e1f60f7210",
"assets/assets/sets/SV1a.json": "e21bd6e62798245323dca537daf6e853",
"assets/assets/sets/SV1S.json": "35a2aee737d0ce5dde9c22a9d33efc4e",
"assets/assets/sets/SV1V.json": "048cb34df0a4c98f293e0625ed2ae00d",
"assets/assets/sets/SV2a.json": "4bb53dcc62499fbc6b9fd07a7f3543a0",
"assets/assets/sets/SV2D.json": "ceeca2b7bdba93d2242ea667cdde5bae",
"assets/assets/sets/SV2P.json": "661e9cccfa8a7ed64bec6fb7294c3a30",
"assets/assets/sets/SV3.json": "fb52d23e913d0c01d499765798ba2c8f",
"assets/assets/sets/SV3a.json": "b4ba2673a9f0abfab9fb4bf93951d7f9",
"assets/assets/sets/SV4a.json": "562616d16b545587ceaec7001beae4ad",
"assets/assets/sets/SV4K.json": "73232f6f12c5cb97bc9bc48ecf52350e",
"assets/assets/sets/SV4M.json": "07a37b360825e83aee7d5dfdb2d79746",
"assets/assets/sets/SV5a.json": "627631148007fb40b1974978605bd811",
"assets/assets/sets/SV5K.json": "2f8b719954858c8f0216a474f5d3daef",
"assets/assets/sets/SV5M.json": "dc85df58e03fce85b8f49b3f6364a7f7",
"assets/assets/sets/SV6.json": "354b50892a571055896250ce52c76ff2",
"assets/assets/sets/SV6a.json": "31629cc705c9100730e5ff9a1ea8e154",
"assets/assets/sets/SV7.json": "b51492abd419f3582f929462e1869fb4",
"assets/assets/sets/SV7a.json": "02c6a13acf2a2d88520eb23c91d8c7df",
"assets/assets/sets/SV8.json": "a4fdbb6744163cdbb79332ae6fffebdb",
"assets/assets/sets/SV8a.json": "69b65df7358ea6b167cf2b9ca6d0de36",
"assets/assets/sets/SV9.json": "fea42eb12bc88ed77f43d9c406fd6f52",
"assets/assets/sets/SV9a.json": "c71971e6e21e5cb82b391099b373e13b",
"assets/assets/sets/SVAL.json": "18b248c00988033d0e10e4b504791e0b",
"assets/assets/sets/SVAM.json": "5c35b9669dff0994ddb8dc4c79207fd1",
"assets/assets/sets/SVAW.json": "ca2e90c9afea93b437a1ff0ed6e0a5a9",
"assets/assets/sets/SVB.json": "c88c5f63804a2f8642b829f0429190da",
"assets/assets/sets/SVC.json": "20c1916aa7c6bcdd9a9f65e31b633a00",
"assets/assets/sets/SVD.json": "27e4a0476de89165bb334d211999baad",
"assets/assets/sets/SVEL.json": "14b1c42d9a9d168b4ad46d8a409014ce",
"assets/assets/sets/SVEM.json": "be4d825fa6799273cccda48fd52c98d6",
"assets/assets/sets/SVF.json": "db8db96a44a1b2e771bc297b7b4db9f8",
"assets/assets/sets/SVHK.json": "0e1aef5d05c2f29d0806f7b31aecf256",
"assets/assets/sets/SVHM.json": "97b38ccb19aa2399c6598c95cc9555b4",
"assets/assets/sets/SVK.json": "ecaeae6d05faa0a1b4b9b2b2b52cb1be",
"assets/assets/sets/SVM.json": "65f3f171e274cccc9b10414b2ed9f3e0",
"assets/assets/sets/SVOD.json": "b1f31820a0bdf7058fd5d8a27a42301f",
"assets/assets/sets/SVOM.json": "0d6ce1186eefdcff8022dc6b735f7323",
"assets/assets/sets/SVP1.json": "c3d6399f565985a3b4f94c0f7bae4f56",
"assets/assets/sets/SVPN.json": "964f0abf6eb8ae1bca232ceb65d61ea0",
"assets/assets/sets/SVPS.json": "f5d29d31620b5ebdb3e50a40ca57172f",
"assets/assets/sets/SVQL.json": "dfa5b3fa2216d83991897db3223bd4d0",
"assets/assets/sets/SVQP.json": "a03ca5910073011f58216c12d53faa0b",
"assets/assets/sets/SVTG.json": "376f0dbc723bbc291c508c246b3ac5a1",
"assets/assets/sets/SVTH.json": "7ac7d8fa2607fdaa558653fe415039c0",
"assets/assets/sets/SVTL.json": "4ccea7bf88c168bf5fd4500da139e344",
"assets/assets/sets/SVTM.json": "20cd184d4c19742ec591948416ab1147",
"assets/assets/sets/SVTR.json": "dc48637a2907544ba18cc7fbef7cce7b",
"assets/assets/sets/SVTS.json": "68156ea6caf2b249acbe31fb98a61517",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "4bba24ebd99f5c4e948be3f138b352a5",
"assets/NOTICES": "fd3f0008b40bf4ded160fe223ad3d882",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "242ecdfac45240e2ca5f999d98a26cf6",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "94729c607c3b63a4f71517e158bf851f",
"icons/Icon-192.png": "ade35e0189d67169ea44a056e1bd54c3",
"icons/Icon-512.png": "320b0e66e1ea59b5d8a8726664791835",
"icons/Icon-maskable-192.png": "ade35e0189d67169ea44a056e1bd54c3",
"icons/Icon-maskable-512.png": "320b0e66e1ea59b5d8a8726664791835",
"index.html": "56ae0fe4ed49da2e20ca8f04ca588315",
"/": "56ae0fe4ed49da2e20ca8f04ca588315",
"main.dart.js": "2b28e01f0d4918a4f8db19b38bfcb04f",
"manifest.json": "2520542c7782ed14976eafccb823ecd3",
"version.json": "c8ba85ee41afa08fa3ddf4be67d439b5"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
