'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "830ddd39866155d9f7d0878356554f8a",
"assets/AssetManifest.bin.json": "5b90ddcaf47bcdbf6c96c8adf2eec93a",
"assets/assets/deck_rules.json": "57c34688cc661834fef9518d2869a130",
"assets/assets/formats.json": "f2e8df905cfa2ee54061803de036fd16",
"assets/assets/icon.png": "b2adaa90c44e5b4000ced55f2d218ab6",
"assets/assets/index.json": "74027991477cad9a53dd825e29c3521a",
"assets/assets/rarity_order.json": "00e5bb47658c47e800af0b9edf553c05",
"assets/assets/sets/AC1a.json": "6fcf3f494fe3f83b91215c17f9fc80f3",
"assets/assets/sets/AC1b.json": "994a9fa05d2417760f0e43b9fba07755",
"assets/assets/sets/AC1D.json": "55b9a21eb89f6a8e5f023195d15373bc",
"assets/assets/sets/AC2a.json": "57a16a4b568eb306597c54bd4a2d517c",
"assets/assets/sets/AC2b.json": "395ddb7f19031af003b666871255e4fe",
"assets/assets/sets/AC2D.json": "865a72c2ac043909c8ae56a16e09e5a5",
"assets/assets/sets/AS5a.json": "96450c6b923cd9d63a1e95df713ead82",
"assets/assets/sets/AS5b.json": "e9a267dab4a470c33ead84eb29179323",
"assets/assets/sets/AS5D.json": "baebfc49abe6727a8f8441ee631e5e48",
"assets/assets/sets/AS6a.json": "ecd363387589b97b2eaa7c57b28c9271",
"assets/assets/sets/AS6b.json": "854e4dc2158b2e08ef29e823eb0a66f0",
"assets/assets/sets/AS6D.json": "3c4e2520d21c2da6e5425793babca7a2",
"assets/assets/sets/ENERGY.json": "541c08f72524cd3f5aa057a690b86476",
"assets/assets/sets/M-P.json": "45365ae81cf87fa2755700c3d86eef9c",
"assets/assets/sets/M1L.json": "8b8bdfe1818837540c2a776b3a5d5f27",
"assets/assets/sets/M1S.json": "3e3e2fa21e8cd7020c2bed94652ec99f",
"assets/assets/sets/M2.json": "9c3e68ff9f237774e9519b7809d0ccc5",
"assets/assets/sets/M2a.json": "06be65c77d542ffe3495800e005a2fab",
"assets/assets/sets/M3.json": "046333ed7756328c32f7a0fa225e5a7b",
"assets/assets/sets/M4.json": "c52d2e6c805284c74d73527179ff65eb",
"assets/assets/sets/M5.json": "68465f6ac665e454c6fcef2576ef4668",
"assets/assets/sets/M6.json": "fae8104410c474f405714e6d0e6924e7",
"assets/assets/sets/MBD.json": "2088ab99bbd868cb75e67e75d9689e61",
"assets/assets/sets/MBG.json": "d2dd9af837f58644e96752e90d072ef1",
"assets/assets/sets/MC.json": "393eea32dfc30073179263851dea4e77",
"assets/assets/sets/MTH.json": "abff5a7977c3fbacf80e7cc6b0aed8b9",
"assets/assets/sets/MTK.json": "b65a6aedb65a07d2ce0ad3deae5c953b",
"assets/assets/sets/MTL.json": "de2d33b0b752eea28e0dbc2ba504a345",
"assets/assets/sets/MTS.json": "1ec7fec4b3bc4a9b508e7fadf445b7e5",
"assets/assets/sets/S-P.json": "7914d7eccdc2d5866aab342ba5f75343",
"assets/assets/sets/S10a.json": "ec1dee7ab5ab4758405b40ae8b08e623",
"assets/assets/sets/S10b.json": "ac744d4d210fafb573cf1b750e300bb8",
"assets/assets/sets/S10D.json": "671f035dbb37c1b945016dfd56df5620",
"assets/assets/sets/S10P.json": "fd975141325b94fa8e8893ca5d9af1e2",
"assets/assets/sets/S11.json": "3f62ee235d6a5c69251d611999f0c5c1",
"assets/assets/sets/S11a.json": "1deb8af2329765202dabc2e0e3902e3b",
"assets/assets/sets/S12.json": "fdbd8803125789d2e43eac591396415e",
"assets/assets/sets/S12a.json": "6da9bedb21d1b9edcae55401e220094e",
"assets/assets/sets/S4.json": "011af2e9fc59331861f3b4e7f17dfd8f",
"assets/assets/sets/S4a.json": "d73dfc7c5c48e1f76587046958abb789",
"assets/assets/sets/S5a.json": "de817ea2dd3c774ae6638eb785c72ae6",
"assets/assets/sets/S5I.json": "bcf1439707e050916388057f781edb53",
"assets/assets/sets/S5R.json": "60ad53f9309be7e0e3c74d4591bc484d",
"assets/assets/sets/S6a.json": "d8e2492e25dabc30b68bf1a04e64f488",
"assets/assets/sets/S6H.json": "80421ef4cf733331231faddf17cc7b59",
"assets/assets/sets/S6K.json": "cef78557217e68bc4f2dd8c43c0be0b5",
"assets/assets/sets/S7D.json": "108afc69325aa6a528f10353e4dd2a02",
"assets/assets/sets/S7R.json": "ec7ae27b2d681f285a5061140469d7be",
"assets/assets/sets/S8.json": "1e32addb460e52155a6e674fb7ecea28",
"assets/assets/sets/S8a.json": "1710e2aa77e9bb49bffc99b9e6d3f550",
"assets/assets/sets/S8b.json": "6a26470b953db9d35103e439a2cf98fb",
"assets/assets/sets/S9.json": "fd82993aa3b4c6dedebd886f58a322a6",
"assets/assets/sets/S9a.json": "d7191b96d958ee4dd14e87f4d34c57e3",
"assets/assets/sets/SC1a.json": "34409076baa4f8cbc0c38fb5aa95e2ba",
"assets/assets/sets/SC1b.json": "d97a7aa20803d42598821932a55c78a1",
"assets/assets/sets/SC1D.json": "360b3c750bebdd8e0224a987da5a3d04",
"assets/assets/sets/SC2a.json": "283e6f8f6a5f23a7bed223ea35c7491f",
"assets/assets/sets/SC2b.json": "a6dd3f357cd6e48eaf7ed76c29f622fa",
"assets/assets/sets/SC2D.json": "426546a9278e6aab1203f4e4b047d65c",
"assets/assets/sets/SCA.json": "38deea5785e9db9ecc52f2d1d3067284",
"assets/assets/sets/SCB.json": "48d30de5a216c0f56ffa29c2e654af54",
"assets/assets/sets/SCC.json": "3681e217bb2b50ef015d53cc7e666525",
"assets/assets/sets/SCD.json": "9b1e83091168dab0ce072b61037c34ff",
"assets/assets/sets/SDL.json": "4dd0c5d5508b8b5510380f0f7493c036",
"assets/assets/sets/SDM.json": "c95b664f6fe0a748a7c49a2cb23aadcd",
"assets/assets/sets/SDP.json": "4effc2333609c47090a4516080716ec3",
"assets/assets/sets/SH.json": "7766c865fddec985b3a637d709cf58ba",
"assets/assets/sets/SI.json": "4ba490a3cfa4b8f86dffdf764f5fd331",
"assets/assets/sets/SJ.json": "044b4f5cbfec8e35326d2248fca01df2",
"assets/assets/sets/SK.json": "95b12f12d416ba1e8612e5c71ff91f62",
"assets/assets/sets/SLD.json": "2646446d1515b8412265837cef0f5c2a",
"assets/assets/sets/SLL.json": "d16db421130ebd19fefd5e804274fac5",
"assets/assets/sets/SM-P.json": "d90b3d23ae7bf891739f13b4e7f6c3bb",
"assets/assets/sets/SN.json": "27efbca80a42eb7984c0739e34589ec3",
"assets/assets/sets/SO.json": "7a8f6dedc98a5004b454fda4870c8195",
"assets/assets/sets/SP5.json": "07526f3bdb711bac09366df40c68ea2b",
"assets/assets/sets/SP6.json": "41864f50dc6d15dbedbcc89a5fef4fd0",
"assets/assets/sets/SPD.json": "4524ea8bf12004052dfb650130c78553",
"assets/assets/sets/SPZ.json": "a4e8039a7e87c50db19ff7adaa2787e6",
"assets/assets/sets/SV-P.json": "c065f8cd6f97b001a6d108fef580ddd3",
"assets/assets/sets/SV10.json": "83ae1a698d7f435cb5e1ce8585ec5847",
"assets/assets/sets/SV11B.json": "efaec24cbb9c694f580703f6a462c2a8",
"assets/assets/sets/SV11W.json": "4a0f56988b9b3073d1b61d872e9633ce",
"assets/assets/sets/SV1a.json": "94f5114ac50c7c0cc8f0c4241b97bb88",
"assets/assets/sets/SV1S.json": "e1020edc6e73e04b9ea0c0d25f3b6444",
"assets/assets/sets/SV1V.json": "8c3db51004f316c356e00f8e98c79cbc",
"assets/assets/sets/SV2a.json": "f9b59f66b15e808ac3a4b2c731ff98ff",
"assets/assets/sets/SV2D.json": "3c89b4ee0c3e91bc61c3680638702fe3",
"assets/assets/sets/SV2P.json": "1cd55fec727ed455e01bb8ad2a1c79ec",
"assets/assets/sets/SV3.json": "ab9317a43a43b487b2c9b00abf5e6db3",
"assets/assets/sets/SV3a.json": "e99bd7a23ad56a51454bc2582292e4e7",
"assets/assets/sets/SV4a.json": "385f54c8b440a1a965c07994d312afbd",
"assets/assets/sets/SV4K.json": "15a3e9d2234e1bb76119fa8303ceeb4a",
"assets/assets/sets/SV4M.json": "34de60a3c56d3f0957cb2b739a73c99a",
"assets/assets/sets/SV5a.json": "9d96df1784d3a629c70faf962b927e79",
"assets/assets/sets/SV5K.json": "d00f1335b6bf20f53c21f3993d7e0a7c",
"assets/assets/sets/SV5M.json": "6ab9e4f58f0e48b386f48542a45a6a44",
"assets/assets/sets/SV6.json": "e9a6d25741ca68399921ad120d709875",
"assets/assets/sets/SV6a.json": "32e5bcafdd45999dde92bad967ee8756",
"assets/assets/sets/SV7.json": "99e28bafd5a14b9bb0098c1a1189e8db",
"assets/assets/sets/SV7a.json": "55807ff352acd060715d96dec3392a68",
"assets/assets/sets/SV8.json": "d8bd3f7f84781e76c01d8a31b2e16714",
"assets/assets/sets/SV8a.json": "6540472eadf79b1bc4e7e7ade456bdfc",
"assets/assets/sets/SV9.json": "199ebf8b94af86f70be39c7974aaa1c9",
"assets/assets/sets/SV9a.json": "c71971e6e21e5cb82b391099b373e13b",
"assets/assets/sets/SVAL.json": "6fe675f06881c3c180d9d36f6199daee",
"assets/assets/sets/SVAM.json": "f32dea588c0423e417aaaf534e70ad9b",
"assets/assets/sets/SVAW.json": "c3eb8c710b260512f53f27819e541a3b",
"assets/assets/sets/SVB.json": "d89f40d9cb644120d466bf918a3bc4fb",
"assets/assets/sets/SVC.json": "9acd3432c49e9265441e9931e6e02983",
"assets/assets/sets/SVD.json": "f47ccc259f12586f1d3ae88376d0cc1b",
"assets/assets/sets/SVEL.json": "e6eabcbba2e62a6750aaae0d9ef0b46f",
"assets/assets/sets/SVEM.json": "b860ccca5c2a56e6602df5cf69ce9cf7",
"assets/assets/sets/SVF.json": "3c18e595cd711b207458e02bb5b8ffda",
"assets/assets/sets/SVHK.json": "b243f86aca8a9fb08ec74ac67539e20a",
"assets/assets/sets/SVHM.json": "f41719c8e41e96e75c5c1276c2308ece",
"assets/assets/sets/SVK.json": "6e4e0df8f5bf58cb49c193f8508f33b5",
"assets/assets/sets/SVM.json": "910b031bcc7b494a50e1cad370a34cf5",
"assets/assets/sets/SVOD.json": "b3bee636b81043af6f1802fe9854eb6b",
"assets/assets/sets/SVOM.json": "27c2e5b340772762722235474fabc501",
"assets/assets/sets/SVP1.json": "0f68c880ba69cd24d8d7dc1326b2a7d0",
"assets/assets/sets/SVPN.json": "1c60517d54c71d137c2d14f5682e6fbb",
"assets/assets/sets/SVPS.json": "9c6f1e8c03582bdf5fc05d2babe5434e",
"assets/assets/sets/SVQL.json": "4717998725bbe3f1c8948cde9224b86b",
"assets/assets/sets/SVQP.json": "150ab4bca527a3d8d8fa096dd156ef78",
"assets/assets/sets/SVTG.json": "ad2b5471e54aa8adc90acd837a5633ad",
"assets/assets/sets/SVTH.json": "57e34a35a93d52fb6647e72c16242e91",
"assets/assets/sets/SVTL.json": "3456e35574959bcbfbf3e8cc78455b28",
"assets/assets/sets/SVTM.json": "e6b46c34cb997d62efa64e81e95a791d",
"assets/assets/sets/SVTR.json": "7a01aa1183d4d579812999ef33e81c33",
"assets/assets/sets/SVTS.json": "831289b6da5459160675356386983e16",
"assets/assets/tags_order.json": "c63bd72cd02017748fbc9f0185ba7a42",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "0314dd392bce877dfe08fc6687910642",
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
"flutter_bootstrap.js": "6f3083b78b659c899e7e286a4000c429",
"icons/Icon-192.png": "ade35e0189d67169ea44a056e1bd54c3",
"icons/Icon-512.png": "320b0e66e1ea59b5d8a8726664791835",
"icons/Icon-maskable-192.png": "ade35e0189d67169ea44a056e1bd54c3",
"icons/Icon-maskable-512.png": "320b0e66e1ea59b5d8a8726664791835",
"index.html": "56ae0fe4ed49da2e20ca8f04ca588315",
"/": "56ae0fe4ed49da2e20ca8f04ca588315",
"main.dart.js": "4d84279301910aa9190cdfc6a3a3a687",
"manifest.json": "2520542c7782ed14976eafccb823ecd3",
"version.json": "ef6ebe203cda748ddac0270cacd0cf89"};
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
