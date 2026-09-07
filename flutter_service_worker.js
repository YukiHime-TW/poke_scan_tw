'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "6bb505596bebc3b1b9bc0dddb1844c17",
"assets/AssetManifest.bin.json": "7b813d83c12d0c7be6810c33f4e49dc2",
"assets/assets/icon.png": "b2adaa90c44e5b4000ced55f2d218ab6",
"assets/assets/index.json": "74027991477cad9a53dd825e29c3521a",
"assets/assets/sets/AC1a.json": "b1f8eef7108ebdceb04c85b991654980",
"assets/assets/sets/AC1b.json": "9f59c50c6d7ffd73ff60bc9b965e4306",
"assets/assets/sets/AC1D.json": "6045fd57d9adfaddbf15b1a1ea22a56f",
"assets/assets/sets/AC2a.json": "ec1473badfdd86d909ec91ae345a7f8e",
"assets/assets/sets/AC2b.json": "71b86f748ad48a973ebcd3250028b208",
"assets/assets/sets/AC2D.json": "a2d590383aaa9b4156adeb46d5d81afd",
"assets/assets/sets/AS5a.json": "ee0c698aa8bc35e8958b7edde34fd6f6",
"assets/assets/sets/AS5b.json": "46cf01ddd31e7a9108f57b2febabc49c",
"assets/assets/sets/AS5D.json": "bc63dee60024819378fd2cb093a2e0c8",
"assets/assets/sets/AS6a.json": "250e8cac440e614ed851a59cc3264fb5",
"assets/assets/sets/AS6b.json": "8228f89379285255baaaf762faec1c3d",
"assets/assets/sets/AS6D.json": "fc33b84dd3bcb3ecfe4b25884ff581b3",
"assets/assets/sets/ENERGY.json": "bd9cab0201c39cec5021d75b3fcac7e1",
"assets/assets/sets/M-P.json": "682222c6d8a90a3a0aa8d807eb9f13e3",
"assets/assets/sets/M1L.json": "afedcd6649963d197b45fe4012e41d5f",
"assets/assets/sets/M1S.json": "135dc034d0bacb40f6dc9e1086513752",
"assets/assets/sets/M2.json": "529ba9b6395bc623b5332fb8dccee08a",
"assets/assets/sets/M2a.json": "b72df25b298ae5fae917be80501d0481",
"assets/assets/sets/M3.json": "c9cbf735636c011d52b69d8bd40346c9",
"assets/assets/sets/M4.json": "beea1de226351a30b51b0bd3e8c0bd6d",
"assets/assets/sets/M5.json": "5cd8123d4d375659df74c7c26061b6dc",
"assets/assets/sets/M6.json": "08ddf49284f2cd1f095a42416d331267",
"assets/assets/sets/MBD.json": "03695633101ec185166dcde08b7c283b",
"assets/assets/sets/MBG.json": "10d5371ee84fa299816f33f7736f8905",
"assets/assets/sets/MC.json": "5907f00f82aae865629531f38170e23b",
"assets/assets/sets/MTH.json": "249263521dbe9944f0323e6c114b3833",
"assets/assets/sets/MTK.json": "f90758a4eb4062a35dfc66ecc031f083",
"assets/assets/sets/MTL.json": "a38de9e13da46552f6ea0610214b21e0",
"assets/assets/sets/MTS.json": "26648dc0d219f866a00a0561967ab8ac",
"assets/assets/sets/S-P.json": "76f6c2e2e344aff2c7b7b0bb6fbded6a",
"assets/assets/sets/S10a.json": "d866be92ef93e33ff896e2e83d72a804",
"assets/assets/sets/S10b.json": "e750b954c5e59da03159a82772ee89dc",
"assets/assets/sets/S10D.json": "01635cdc5479bb971f03d3aa9668f472",
"assets/assets/sets/S10P.json": "16b86db875b312c2bc3de0ac7487a54f",
"assets/assets/sets/S11.json": "642d0f034049e51decfb80d2505fad2b",
"assets/assets/sets/S11a.json": "640eed2e91440672b61b85125227dfd3",
"assets/assets/sets/S12.json": "bcef05ae5cb0e0e30cdf2724a8186be2",
"assets/assets/sets/S12a.json": "df204e265ea0cc1160c269096c842c04",
"assets/assets/sets/S4.json": "319723b294e708daf3425eb4e1fdb5c3",
"assets/assets/sets/S4a.json": "1289794ae56e8d669004fa6a39266f2c",
"assets/assets/sets/S5a.json": "71f9a6b4e05f17488152dd5bc564c7c4",
"assets/assets/sets/S5I.json": "cd72116ce8c8d0c24febaabb16ead604",
"assets/assets/sets/S5R.json": "1bd1e02e598233e7d19abe1e75ca6a0c",
"assets/assets/sets/S6a.json": "d37389a65cfd4f2d5ab2647b8367f44d",
"assets/assets/sets/S6H.json": "2669421008be0fc7ba0bed5a6f920e02",
"assets/assets/sets/S6K.json": "8a7b2055cc51bc4153766330687589ff",
"assets/assets/sets/S7D.json": "992296f9e7ca96b47c5a437e8ee7471f",
"assets/assets/sets/S7R.json": "e29bd502e7c3c6e0aa88af399b7e1b36",
"assets/assets/sets/S8.json": "8093a2b418ff974fe5f8d818391dd518",
"assets/assets/sets/S8a.json": "284e90d0fee0a4271d03f564fc351914",
"assets/assets/sets/S8b.json": "1601e5e7736c68ddd1d21f53f5401df5",
"assets/assets/sets/S9.json": "5d1e85107b6434497ecdc788288d396f",
"assets/assets/sets/S9a.json": "4ee1c1922fe06c9788894e8304deb993",
"assets/assets/sets/SC1a.json": "bbc7a247c7b1faacfc8ca9465de99afe",
"assets/assets/sets/SC1b.json": "ceb5dfb74e197c1df19b1ec21205991b",
"assets/assets/sets/SC1D.json": "d7fa1b1370d1b4cbe9a8cac1de1ddc9c",
"assets/assets/sets/SC2a.json": "0f6155eabd1c13f963e8f160ef83f805",
"assets/assets/sets/SC2b.json": "d601305758232e3ed34bda9abba61feb",
"assets/assets/sets/SC2D.json": "9215284312db1ca7604b4e7add41ca37",
"assets/assets/sets/SCA.json": "7114b17d6e2443b1e40a0d77b5e0ecf2",
"assets/assets/sets/SCB.json": "0a03588b6c8c640c1267d63512dabc03",
"assets/assets/sets/SCC.json": "aa5206785972ab2cff5ae96e6df95dbf",
"assets/assets/sets/SCD.json": "4dc3e55fd11afc36eceb0e01f38f3343",
"assets/assets/sets/SDL.json": "ee903cccf2e5e89a2618861a1dc8327b",
"assets/assets/sets/SDM.json": "18bc69e1334063d01f4ee18a77d74efd",
"assets/assets/sets/SDP.json": "34ab476dcc68a1e4cdb66eb924950d5d",
"assets/assets/sets/SH.json": "8b832250f4228bbfa63875d4f54cfc82",
"assets/assets/sets/SI.json": "fed1abbc8ec3f73b990dcae9d40663e9",
"assets/assets/sets/SJ.json": "6c908372f070e418ceb7661b3b4f2974",
"assets/assets/sets/SK.json": "7a2e3ddca363c525c13bf4fd6fb59d00",
"assets/assets/sets/SLD.json": "a17bdc7f5def80375438850c92fcf683",
"assets/assets/sets/SLL.json": "402bb7cf801ead1dd7279a8fbb85d4c6",
"assets/assets/sets/SM-P.json": "d47526d99849243496a7afb653ce4415",
"assets/assets/sets/SN.json": "032ade2c4fa33aab88b524eef776a278",
"assets/assets/sets/SO.json": "1955eb4a6bd2fc7ec5f1543e6d7b948d",
"assets/assets/sets/SP5.json": "d9f97b2b8170d6082e40e7407c94e2da",
"assets/assets/sets/SP6.json": "d7f3f679fda33623d06d60e49e012a59",
"assets/assets/sets/SPD.json": "4d38e8b1f30072f7e9390d2d2900ab42",
"assets/assets/sets/SPZ.json": "e32b5024f8f8fb6e1c1458384b06804c",
"assets/assets/sets/SV-P.json": "47dc33b7e5c45d559341ba559c6f16e0",
"assets/assets/sets/SV10.json": "8d5f6eb7fb8bed1973aa112c28caab33",
"assets/assets/sets/SV11B.json": "4be5adc7a0c8e6f2acb6cdf760479878",
"assets/assets/sets/SV11W.json": "ca5ee7c8ff408712519a9210188634f4",
"assets/assets/sets/SV1a.json": "2f649dae03f99490ff234b09cde9a38b",
"assets/assets/sets/SV1S.json": "4728719ebefcd317dabc854f91967e46",
"assets/assets/sets/SV1V.json": "9289655fea77e5edb1b6236972e6f8bc",
"assets/assets/sets/SV2a.json": "57000389ed8cfa81c9f6ee53849cfd20",
"assets/assets/sets/SV2D.json": "78e66ae0074904444b498ab09098eab6",
"assets/assets/sets/SV2P.json": "4edebc69ae23941b7c6e9eb3e71a136b",
"assets/assets/sets/SV3.json": "2102d4906c96aa78246751299390dbda",
"assets/assets/sets/SV3a.json": "5ca4c91930853ce25797a7a48bff6257",
"assets/assets/sets/SV4a.json": "13e2731c5a35fa9c4cab524750875ba2",
"assets/assets/sets/SV4K.json": "6b5f8942f35bd7bd12788081e25082bc",
"assets/assets/sets/SV4M.json": "546d8142087d67da2cb9cd02130b5cce",
"assets/assets/sets/SV5a.json": "8ba97960a105184fe3294b32f8a506f1",
"assets/assets/sets/SV5K.json": "305e8e5209623b9fec1a694e263d6d6f",
"assets/assets/sets/SV5M.json": "dc85df58e03fce85b8f49b3f6364a7f7",
"assets/assets/sets/SV6.json": "3126b52fcf2e5fffa6b382d0e93b0a5f",
"assets/assets/sets/SV6a.json": "b61ccf12ede63a486a51856fe7fa5eca",
"assets/assets/sets/SV7.json": "f1dcb2223ed0f880850986ec1a9dba60",
"assets/assets/sets/SV7a.json": "44c10c1576bf98a6682f91894497e650",
"assets/assets/sets/SV8.json": "46f63364eda8c1b43b2a27bd3b1a2f0b",
"assets/assets/sets/SV8a.json": "ca9a594091b717e78d3c20bac841797a",
"assets/assets/sets/SV9.json": "2ef992d230829b5decbcaf972f00ddbf",
"assets/assets/sets/SV9a.json": "e26cde39f8bf0b916ae96b3193df6c60",
"assets/assets/sets/SVAL.json": "18b248c00988033d0e10e4b504791e0b",
"assets/assets/sets/SVAM.json": "5c35b9669dff0994ddb8dc4c79207fd1",
"assets/assets/sets/SVAW.json": "443dabadfa11ee866a7f35c47602cf1b",
"assets/assets/sets/SVB.json": "a40daa1dc3acfbdeb963a3e47a732365",
"assets/assets/sets/SVC.json": "20c1916aa7c6bcdd9a9f65e31b633a00",
"assets/assets/sets/SVD.json": "5facddfc3d33d7d6f535a24410183f25",
"assets/assets/sets/SVEL.json": "14b1c42d9a9d168b4ad46d8a409014ce",
"assets/assets/sets/SVEM.json": "be4d825fa6799273cccda48fd52c98d6",
"assets/assets/sets/SVF.json": "db8db96a44a1b2e771bc297b7b4db9f8",
"assets/assets/sets/SVHK.json": "e5e82322d83d1dee1c9189c35afafd20",
"assets/assets/sets/SVHM.json": "45bf8db2726fc1b0382208a47a56d55c",
"assets/assets/sets/SVK.json": "27a985b70b6686117016c47c06de7fe3",
"assets/assets/sets/SVM.json": "6df0e4e4d50bdc1ecc789647c40cc516",
"assets/assets/sets/SVOD.json": "97a491176c724adff204c33db9eb0758",
"assets/assets/sets/SVOM.json": "c366add4e8d5789fb56f8f6f5d075df3",
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
"assets/fonts/MaterialIcons-Regular.otf": "15ab2156a74143248c5121cf5af02348",
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
"favicon.png": "0835c1dc88cc0099660eac0838d0e28e",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "0bf643b6738fe7e1eed21236955c970f",
"icons/Icon-192.png": "d6e530b590ecd87177f3db22bcc7abc1",
"icons/Icon-512.png": "f23437636b23eac7fde06e06307477b8",
"icons/Icon-maskable-192.png": "d6e530b590ecd87177f3db22bcc7abc1",
"icons/Icon-maskable-512.png": "f23437636b23eac7fde06e06307477b8",
"index.html": "b3b43f14c72fdfbd8e443fa37c9a243a",
"/": "b3b43f14c72fdfbd8e443fa37c9a243a",
"main.dart.js": "f6356bbda5454872a54a8c0b920c2674",
"manifest.json": "03213b3d470b28b9fd5fa78ebd963f84",
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
