'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "878450852c49f9686025a2588dd74c09",
".git/config": "8ba81c336a9ce0e6e344c7ebd6cf8ff4",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/FETCH_HEAD": "cf7cab79ad0d039f660f11e4a04adb88",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "db162a740e80d9cbc664e868ab50b6c5",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "c252525cf68f54e0dfa1db521523e3a4",
".git/logs/refs/heads/main": "bfb63af40d1ae6a44c5aa21af367e0ea",
".git/logs/refs/remotes/origin/gh-pages": "3307716b912b038533c09744a475590b",
".git/logs/refs/remotes/origin/main": "2c1e72c297075f680a5a7372f9c8d087",
".git/objects/07/212e2425898161a55c4956dda2ee0434a75447": "4b8f4767b856d9fbd97dee832aa4abf7",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/12/7c01f7e000db820ebc90f9ffcf7c72f1c82431": "547e517c7a3b3f469345df8165d7ee5d",
".git/objects/14/7a769c15f566bc99ea67f0c028b6b6b04a2575": "7184d25bf26efdbbd6c7bfb21b5f2fe4",
".git/objects/14/e3f460520a869124c66361c426c38e4c6239ea": "26f0e1d4f738ad47ade9f1543a894b0a",
".git/objects/15/5a63a1691ecc89d02fc10043d39ef7530e9ee2": "e104cd2bc12b2175d94f7572ddaabf7c",
".git/objects/22/1d3503e34a95a8b80bc56c8915e501f143e8f1": "182e7f90ddd0faf92b0fb0549ed20456",
".git/objects/29/de7158e0ebe1035d33161efdaa72facc4707e4": "d969b688bd158ee6df5ceb1a1c3a2301",
".git/objects/29/ebf9c9c6172dda7aed1a1b101d8cb2f3f693c9": "439be4ff4c6dff97f0ae259dc60fda25",
".git/objects/2b/48305bc527ae8ccb201304f9820c0115b71739": "0821a34ca1a163f23f3f3a5a7686f73b",
".git/objects/2b/f5341bd285185b324fd7fc65e3fa25e724be26": "acc4458d1f0123b35ed29ee76454092d",
".git/objects/2c/f005964966e54d7e733b44e4df4a111a976b7d": "95ec65ff19ed4ff88d5c76b0e3cbc9a7",
".git/objects/33/a02678e0b23304310faab9e3cafa66a5f2ae15": "9d221220531ce50d12e02b7d834ec994",
".git/objects/36/83e9d9403a6a17c91f6fc6a63b3eb273f39851": "1ec2f879188be70102765b499a2fe97d",
".git/objects/38/cb2929aeaf06f2a307c8116b0fcfbee063a44e": "0887d08c17c779951fb7457631858dc7",
".git/objects/39/c578482b74f42b7e0187fbc0a7398eafb16345": "756b344e50c7f89061efbbc2b4c08ef7",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3a/bf18c41c58c933308c244a875bf383856e103e": "30790d31a35e3622fd7b3849c9bf1894",
".git/objects/3f/1a65adaaaf4662038a1b14087285faaa09936c": "4e7f5f11e067335498d2d9878c37f1c1",
".git/objects/41/48463f4cf57577d85a3fd444ab9b96b337a269": "c726d14dfab6191f37088fc08dd1f99a",
".git/objects/4a/9029a65660478d1b13b8f38ec27c5ee7c86dff": "3d5553aa1fe40f68debdd8dc8ff07cd6",
".git/objects/4d/2eca6781456407a6d69361ee5b59b28e92ab9c": "57947879e2d3cc4d63856fa826a61328",
".git/objects/4f/4b3124b6766f8da35452517f242faae43d8894": "773888a13c0e2c78c1ca8a987729bf30",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/53/115f1ff17016f926519896f0e99d49ba62a0eb": "603d4c0799b690d27c149d6dbd5d5512",
".git/objects/58/d5f899223affb50b01e6767a8dc899173199d3": "90fa2a8ca0dc22f366418f9855cfe167",
".git/objects/5b/da75c557145ef4b33642f9fc1c091e2282a9dc": "1b841ee17c5b46a4fd6c191a6dd725b8",
".git/objects/5f/1a31195091651b623ee3bac7e3b579a46c93d1": "17b03a411c3c22e53fbac9776c9a165f",
".git/objects/64/71aa74587da7d8db1c4db68304f4f10181c631": "0360bcbe9d4a67298dece509fefefa60",
".git/objects/65/88e890981c519540fa7e95c89a76c3f04a860c": "0eb18617876a4ef5250f0b76b17963f6",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/6b/a03a9b59820c033665b8aaf40b6e5f885bcf61": "4261ae37d5c479dce52bfd69100d1b9f",
".git/objects/6b/cab6a04668077130a0a63568428b285ac78bfe": "7721096c704ea996cdb3475ad46246f4",
".git/objects/6b/d7361640b28d0538c946e05b55899bb96d0859": "857e43f637a348320c5b5afc93b9d669",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/74/955436d93b95b945046f91a10a58b65477ff33": "bca333ffcd355ae464ad7499b74eb509",
".git/objects/77/533dbfe55f4788f99f44bab93f8ef8339b8e5b": "217f86f7ee77b4d311f05e00fdd5ecff",
".git/objects/79/a1c44f0bd2c89d634e73ce3a25ad4b37c4e01a": "0877b5c280e64c32423e6e08e90b9a66",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/7d/1a439d831cbc372fc93855b87c2132bb4d6938": "bf33ee2e6563ab5a8e04ef48d3860205",
".git/objects/7e/8a2c525f080742bb483ca8c9ee6548d1331afd": "e6928c2f3150cf869a5f2cb13a72ae00",
".git/objects/7f/a471c7a4d547fc1e6af7208f8a0dd2b6f1a5bb": "f1a93c80a9ceffef07dbcefbda1e0e2a",
".git/objects/80/5f90c2d69b103773e9d98fecfc712be90c6808": "6b4951cce90037c0087d24f0f5827822",
".git/objects/80/c0726758776add8bb24832869e48fc3abbdea5": "91af34c605353475ac18886ccf91378c",
".git/objects/82/b358efb900e7df75549255ccfda7d65ce8a73a": "20cafca040450e0d8b85d480993205ca",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/86/49ac1f1da018991b284e79ffd546fa0f0de691": "1c8eb13a0d0d5bbea72cee6cc7416da5",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8a/c25bc859a81c968ca691882702cafe92fc120f": "354730e5c0f209b53ea4b59d7e3c10db",
".git/objects/8a/f20b805ad4382a02c6a3a7ba1457fd6de627ff": "45b1e8d85513d53cdfb8c32fda24e0ec",
".git/objects/8d/168aa94339a2a365320e978533e31821fc1d21": "e43bd51e882681865b4f1cec5a2c32d0",
".git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
".git/objects/8e/9a1743abff473db146e93793326fb055edf8a0": "5fc174ea3bc5bcda091e4ab579e0d8e4",
".git/objects/92/ad158dc64efd666fc590a1ca2d97bdd79f6944": "c9adc93c29cee5d8b1ea34bbb14afea7",
".git/objects/92/ca1136cbc3230f345b6ced05a34e401f0a88b9": "1882737a1287998975d7812525c29c60",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/97/42789b5a696b9a6543c5968465f9cf8862f3ea": "b7a63142c4981da2b828039703f5112c",
".git/objects/97/e2e0d06c4d33f8e8f84b1e88a9db241df5a12f": "d5f25e6b2d88c427dc2459e72b8b5cab",
".git/objects/97/f5d9ab0b7a43d8da4016fd525503375150426a": "f7846f36635f002983d819db086b8485",
".git/objects/9a/ba4f905613139919f977b012de761ae292354a": "5a8ded32b8c9cef19fe95a5e076a43f8",
".git/objects/a0/48f58e5699135b91869e2b37e04998b9e57f86": "558861af9f372504b6b99190c00b0fa9",
".git/objects/a3/b4c41c429a383cbf94b41b0861bfdcf5dfc9e5": "0bffcd16531a0ce81a8b50d6e768026f",
".git/objects/a4/399da119d43fb86eac873ea838dae694fe1f20": "5e73078d134857240dc0ea0a0e25abc3",
".git/objects/a6/27648e9b0e240a28bd5753560a0d9bee6d7527": "1048ecc9593b29e6faab7dad8993a832",
".git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
".git/objects/a8/6782305ff80ab030b0e46f19e4a100c60f1ff6": "f90ac8649b8c8fdda40c12d8afc59fc2",
".git/objects/a8/bddaa4fff677065bee038fc25fb7d0db336f72": "6bbb24ccab03dc37650bcb7f2a2ca8a1",
".git/objects/ab/dd1a83969bb71270cde176537bbdbf5133a37e": "528220086ff7ec6afb9bd3d719edfc31",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/af/803374814c57400efcec457269250f3ff4df6d": "f27ff2cd244db348842ec5f233b102d3",
".git/objects/af/85b1da83e5a19e031b53755465eba27124523b": "65459a12572cf30603b71ad371f5849c",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b7/e804a0cd9ae8f8a835c5e353808cc50b762ec8": "6736885a7b7b9f86e130b3c99c53bee1",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/bd/3ec181932252201389d879844c16dcf6ad228f": "a28414d4c3b29ef569c2b8d1e89cb9da",
".git/objects/c3/3fb722132dc6d5535ed9d32eab993932fdc82a": "5b2c6c52ff5efa41313211350fea3a9e",
".git/objects/c3/7130fb3a6215b065f72e9a36cda7ec941a2ef4": "404dffe895815d382ae078f68f3dccd9",
".git/objects/c5/d6c2f317ee06723fc5570e7429d82a40bbe6f4": "d497a3445b0494e7118202caa093f0a8",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/cc/e3ff22ff1ec7a65f964bc74e9b8587e614f2ab": "6023096b59ac9f0bfddfc24c1a5bd552",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d9/41e01d0d855a4190d61949776073a0a0a2a6b2": "d02a9d4681049c6fa1e09a62434145ec",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/d9/62c4d1c9e7467abf565748ec63d56f72df5bd8": "351fb026793bc97f57df95410de70e0d",
".git/objects/dc/5342f59e3b915dbb658519aa3698802a16991d": "a5472090883cce4f151ab81a272b70bb",
".git/objects/dd/83d574c902eb2534af3d0e80165fcb31c8a40a": "4b232c5836285097512d567e509a960a",
".git/objects/e4/889bca750d0030d87609c517198c49ce859497": "ccd2a13e4be3a3817053d76a8fd9bb00",
".git/objects/e7/1cad1593ec8eebf332bb0ee4bdd31b85a0662f": "1c1d57d9a200f0f446160d9f872935fe",
".git/objects/e9/adad60e26baed57915e85a9d0a9b65b1c57824": "2493294e44e8e3739a3a42270b7febb3",
".git/objects/e9/c225cd807ae2c7fd8ee0f6bf36a8ce6da688ee": "8ad60438944d9af6cf7c8a90ca927c30",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/f2/34c19deb6aa5b83fc910326ce33d25b0a4eea9": "8ae3718c4400ca8392d526810fe9d1b6",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f3/75474fa2b6a2c60e67c020adff57789c46535e": "3b99641a946e25f0421426f1210d8139",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/fa/df4c01776356f32c8614185e17cc3c2c8b8dec": "75d7afd0300f60b6f855e89c3c903b96",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/fe/571ab50cd4feee36fe3f9fc57cf0c50ff0e2bc": "115d149227d1069547282d9d6ef0ed09",
".git/objects/pack/pack-f4d0230d183e552cb013d6dd3fe7df4a4b7350ca.idx": "cec01f9e92638d89bd3383c1c61eff72",
".git/objects/pack/pack-f4d0230d183e552cb013d6dd3fe7df4a4b7350ca.pack": "a7a844159080910d3ffbf75bac346bfe",
".git/objects/pack/pack-f4d0230d183e552cb013d6dd3fe7df4a4b7350ca.rev": "46728bd5560b8b8eae3308b9285873d6",
".git/refs/heads/main": "80aac702f733e5cfc282134890fb1351",
".git/refs/remotes/origin/gh-pages": "80aac702f733e5cfc282134890fb1351",
".git/refs/remotes/origin/main": "7ec6476abe5e2b7cc977247f6ee12040",
"assets/AssetManifest.bin": "6867382e696c69e14055aa29c98c3996",
"assets/AssetManifest.bin.json": "1bab74c5b085e5fd6b20c0339fcc2f32",
"assets/assets/data.json": "8d7ee0a59d92e82991926d7071f0a83d",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "b6d85cd9089dfe5bfe9cea647ddbae42",
"assets/NOTICES": "83a39da030ffa7b43b520290b68e6afb",
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
"flutter_bootstrap.js": "8bff0f85d63a37caf27ffab9e7fa90eb",
"icons/Icon-192.png": "d6e530b590ecd87177f3db22bcc7abc1",
"icons/Icon-512.png": "f23437636b23eac7fde06e06307477b8",
"icons/Icon-maskable-192.png": "d6e530b590ecd87177f3db22bcc7abc1",
"icons/Icon-maskable-512.png": "f23437636b23eac7fde06e06307477b8",
"index.html": "e986d0814acdebd5a999f95fd35c719f",
"/": "e986d0814acdebd5a999f95fd35c719f",
"main.dart.js": "e1411b57bc81966742cb81626058b79d",
"main.dart.mjs": "1b264b69ad7fa8d0c1df7eba9049c94b",
"main.dart.wasm": "4292404e88ed8c8afa76a6be40e5a81d",
"manifest.json": "508d2cbe052c12961fcf538eea3af484",
"version.json": "e3057dd2cf0f04ddad25ad11e3343408"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"main.dart.wasm",
"main.dart.mjs",
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
