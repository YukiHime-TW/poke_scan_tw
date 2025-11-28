'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "189c1ffaf62e224bfccfbe361b74ad77",
".git/config": "8ba81c336a9ce0e6e344c7ebd6cf8ff4",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/FETCH_HEAD": "9eaa82ad16d7f4c97f82650b68754e93",
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
".git/index": "f76760998a62f33211bc7b1bf9ed4dee",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "df2542bd6323a88595e224ed924d2a1f",
".git/logs/refs/heads/main": "dd0f6692f20da3a88ec27b3101d88e68",
".git/logs/refs/remotes/origin/gh-pages": "72fdd1ceaf6b9682689d333e2c895012",
".git/logs/refs/remotes/origin/main": "1b549005d647bf8f8b5731b6f50dc6b6",
".git/objects/07/212e2425898161a55c4956dda2ee0434a75447": "4b8f4767b856d9fbd97dee832aa4abf7",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/0a/b0063ae54c086be2e63bedb0c15fe332da041b": "ee95aa662baf25c0700b2126a741ebea",
".git/objects/0c/1de9c8494f1eb001ced352383e9857bc977eb1": "7b7722b8acf807d9732c39a97751b22b",
".git/objects/0d/4d12a5737f97bfae52bdd65157add010f81edd": "b8a1fbc593b902d4e8de9da877e392a9",
".git/objects/10/1acd2fe9c64b5fa6da7aa28a4f2bbef32114a6": "1b53eeb9a81e9d9cb39599f61e181695",
".git/objects/12/7c01f7e000db820ebc90f9ffcf7c72f1c82431": "547e517c7a3b3f469345df8165d7ee5d",
".git/objects/12/cd97d299ade1e0706749cd0d817fa617b6ed34": "e846f150f5dfa2aaa747f553f2a73523",
".git/objects/14/7a769c15f566bc99ea67f0c028b6b6b04a2575": "7184d25bf26efdbbd6c7bfb21b5f2fe4",
".git/objects/14/e3f460520a869124c66361c426c38e4c6239ea": "26f0e1d4f738ad47ade9f1543a894b0a",
".git/objects/15/55847bb3553f5eefcd9fc7185bc95fadfd6a86": "ea198f345abcdc0b44f181b7ab9817c6",
".git/objects/15/5a63a1691ecc89d02fc10043d39ef7530e9ee2": "e104cd2bc12b2175d94f7572ddaabf7c",
".git/objects/1a/827fb745b6a1cb9bdfadae3ef986b65a541143": "0eee777bf6e10678a96f2531824f34b7",
".git/objects/1a/e4b6c0ce4a346308c913e22285c345aaa51d78": "2d9ae86cac71f2f1fd608e9779e4c545",
".git/objects/1b/e1dbb5886a3e71c82c22e233f8192ec9b90d66": "78da5cc5b16ed9e650067a343c96776a",
".git/objects/1d/9b77e63ad78fd9443988591f06911d5c4bba01": "48aa24975143d5c0eddba3590910f150",
".git/objects/22/1d3503e34a95a8b80bc56c8915e501f143e8f1": "182e7f90ddd0faf92b0fb0549ed20456",
".git/objects/22/ebaef978ef5777bfaefd176f9633eaab501268": "5f72bf8100fd31fb7610734733cdfd08",
".git/objects/23/166b36cd1eb71e7b5e94cadb4d467eba91bd0d": "95a3f675ee838362d0b955f859928c18",
".git/objects/25/32af929f2e79cb9cda8b18b6a0044228146fce": "23af5e824a1914c29f40f61116b10969",
".git/objects/29/de7158e0ebe1035d33161efdaa72facc4707e4": "d969b688bd158ee6df5ceb1a1c3a2301",
".git/objects/29/ebf9c9c6172dda7aed1a1b101d8cb2f3f693c9": "439be4ff4c6dff97f0ae259dc60fda25",
".git/objects/2a/5ee4263e1ef528d96f4dc940c941d76eee1ed7": "09296c7241ef21b64cc374c5b3f95562",
".git/objects/2b/48305bc527ae8ccb201304f9820c0115b71739": "0821a34ca1a163f23f3f3a5a7686f73b",
".git/objects/2b/682e5b466636cff725a75a4967bf5d87a9e83f": "589823a512395d352edc3b56f1232719",
".git/objects/2b/f5341bd285185b324fd7fc65e3fa25e724be26": "acc4458d1f0123b35ed29ee76454092d",
".git/objects/2c/ddd80583df2c8f86ee44e2a446e815c40117f3": "6199d803246f6c606370f1504ce0e590",
".git/objects/2c/f005964966e54d7e733b44e4df4a111a976b7d": "95ec65ff19ed4ff88d5c76b0e3cbc9a7",
".git/objects/32/c0fce7203acd6e58f87c93fa8a657bdfa0b55c": "17673fd0542b3b2b57082d6c5093a49d",
".git/objects/33/a02678e0b23304310faab9e3cafa66a5f2ae15": "9d221220531ce50d12e02b7d834ec994",
".git/objects/36/83e9d9403a6a17c91f6fc6a63b3eb273f39851": "1ec2f879188be70102765b499a2fe97d",
".git/objects/36/cd36c94e340491a759294203b68ac8dfbb7bac": "487c693541c6bfda870ff88ae5c84ea8",
".git/objects/38/cb2929aeaf06f2a307c8116b0fcfbee063a44e": "0887d08c17c779951fb7457631858dc7",
".git/objects/38/d1d1d9b3704ea7f88a48ebc1096432cde68ca1": "e604e40f5522d8ca4bdadc0b05974757",
".git/objects/39/c578482b74f42b7e0187fbc0a7398eafb16345": "756b344e50c7f89061efbbc2b4c08ef7",
".git/objects/3a/099fd31d7f45872bef476c477060b9159867de": "760d85d06ec8aa77ea2374dd91e1b19b",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3a/bf18c41c58c933308c244a875bf383856e103e": "30790d31a35e3622fd7b3849c9bf1894",
".git/objects/3b/a18064a8a506408ccd5519643fba15aaa0d960": "2ac0fa407dc06a7f56c25def4ce72cd6",
".git/objects/3d/93c52fbc4e4877b2bd6ecda53908b2fa042cc4": "044366cf5ff7377612c692b38dfca15b",
".git/objects/3d/a30dcee96cd79b64e5b48ba1ef272332748791": "86d3d373506e11bb1b8dfc75526e3819",
".git/objects/3f/1a65adaaaf4662038a1b14087285faaa09936c": "4e7f5f11e067335498d2d9878c37f1c1",
".git/objects/41/48463f4cf57577d85a3fd444ab9b96b337a269": "c726d14dfab6191f37088fc08dd1f99a",
".git/objects/44/ea1e7be1c31fa26c6115dce57970137f2529f6": "515659c3f4f18225f13b74d42d741da7",
".git/objects/46/dad9c6da326d80b77f284242ed429f337e3653": "279c4fbc06ed9e964a71a2e88bebb81e",
".git/objects/49/dad2d729f765f8aa9b28d4334615d25a878120": "01d8c92969132cd6bf5c4e53336a6499",
".git/objects/4a/9029a65660478d1b13b8f38ec27c5ee7c86dff": "3d5553aa1fe40f68debdd8dc8ff07cd6",
".git/objects/4d/2eca6781456407a6d69361ee5b59b28e92ab9c": "57947879e2d3cc4d63856fa826a61328",
".git/objects/4f/4b3124b6766f8da35452517f242faae43d8894": "773888a13c0e2c78c1ca8a987729bf30",
".git/objects/50/1fdaf4c3704b23c5c1bb62f725c8bdf174b40d": "1c7b142b70cf4b0eb7a0bd52dc25a3c9",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/53/115f1ff17016f926519896f0e99d49ba62a0eb": "603d4c0799b690d27c149d6dbd5d5512",
".git/objects/54/f2fb780971121cdd63ce3c6c8e94556fccfa30": "1289514df227d0bb6ee764f6eacf355a",
".git/objects/56/d0f2d6c0cd05f2b603ba2c1dc574fc01053121": "75a3153df61aa27187a12cea29d23348",
".git/objects/58/1c158f032dc69cbe4b32fe175640d3bc889aea": "99160f6075ae9fc8bfe230a276636554",
".git/objects/58/d5f899223affb50b01e6767a8dc899173199d3": "90fa2a8ca0dc22f366418f9855cfe167",
".git/objects/5a/89fbd95a69e7a3eb8e59f6a64512e9ba9fc31a": "90cfca76be5352d6ecd472dad72157a7",
".git/objects/5b/da75c557145ef4b33642f9fc1c091e2282a9dc": "1b841ee17c5b46a4fd6c191a6dd725b8",
".git/objects/5f/1a31195091651b623ee3bac7e3b579a46c93d1": "17b03a411c3c22e53fbac9776c9a165f",
".git/objects/60/6eea825fc7b34a0d41213fead67b8f904948a1": "ae9739a25093d7fb3014871264d4884c",
".git/objects/64/71aa74587da7d8db1c4db68304f4f10181c631": "0360bcbe9d4a67298dece509fefefa60",
".git/objects/65/88e890981c519540fa7e95c89a76c3f04a860c": "0eb18617876a4ef5250f0b76b17963f6",
".git/objects/67/253401089ba3f38f4dac28a7f3042f1bcff2ab": "231b88f03504b6587dad041230c099cc",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/68/57b2dbec40d4056ace5948f9f0b39ce07e90a2": "d96b4f17edb1d7f0a7a522ab4add36c2",
".git/objects/6a/ffb12caa6848ec8ae22a672e44b3611d5a4b07": "7f55601cc7941652dd85ab76bc000744",
".git/objects/6b/a03a9b59820c033665b8aaf40b6e5f885bcf61": "4261ae37d5c479dce52bfd69100d1b9f",
".git/objects/6b/cab6a04668077130a0a63568428b285ac78bfe": "7721096c704ea996cdb3475ad46246f4",
".git/objects/6b/d7361640b28d0538c946e05b55899bb96d0859": "857e43f637a348320c5b5afc93b9d669",
".git/objects/6d/246096373e5205f3ed043894a4178d8121e6e4": "47eedf7eb8f0c898ca3cc2f266e5bb36",
".git/objects/6d/d2dfe3fe5a4324ba543ce8a2c391830ecc5719": "6ef9089ea4e81ec93149c4434b6b31a0",
".git/objects/6e/9de9f6451ec0fe5abae70e8d99c83c85d471c2": "5514771f48f96708318cfd1a495c3033",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/70/54d2e900ad9b26fdf485af6fdae91e3ac1e042": "a94952473a64cd3243e9a30a784a38d2",
".git/objects/74/955436d93b95b945046f91a10a58b65477ff33": "bca333ffcd355ae464ad7499b74eb509",
".git/objects/77/533dbfe55f4788f99f44bab93f8ef8339b8e5b": "217f86f7ee77b4d311f05e00fdd5ecff",
".git/objects/79/a1c44f0bd2c89d634e73ce3a25ad4b37c4e01a": "0877b5c280e64c32423e6e08e90b9a66",
".git/objects/7a/66b3fc98af591c3dfac92babce6eb2da6f7516": "8f219c3125d94fb4d5a9a45dd0c42e7d",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/7d/1a439d831cbc372fc93855b87c2132bb4d6938": "bf33ee2e6563ab5a8e04ef48d3860205",
".git/objects/7e/8a2c525f080742bb483ca8c9ee6548d1331afd": "e6928c2f3150cf869a5f2cb13a72ae00",
".git/objects/7f/a471c7a4d547fc1e6af7208f8a0dd2b6f1a5bb": "f1a93c80a9ceffef07dbcefbda1e0e2a",
".git/objects/80/5f90c2d69b103773e9d98fecfc712be90c6808": "6b4951cce90037c0087d24f0f5827822",
".git/objects/80/c0726758776add8bb24832869e48fc3abbdea5": "91af34c605353475ac18886ccf91378c",
".git/objects/81/7b44aa36bed4461d2955d486820aebdbda5a9d": "bf6c2e52e904e47ce241bc59be1dfcbe",
".git/objects/82/b358efb900e7df75549255ccfda7d65ce8a73a": "20cafca040450e0d8b85d480993205ca",
".git/objects/82/da494a36e7d46c6a58a025c4f5db8f9918a6ff": "c312e0da950288c402fb4600dfb6e438",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/86/49ac1f1da018991b284e79ffd546fa0f0de691": "1c8eb13a0d0d5bbea72cee6cc7416da5",
".git/objects/86/f271049dd8758ea30b39b6d112a5c5f4be4c11": "c5b164fcd519b498988608505bead7d1",
".git/objects/88/90c936b048f92ab8d9d1866d89b45926a747bb": "f848076f6d0c02c5d6b163f9eafaae0d",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/89/51f36402875fff70cb3d56a4f046a11080f727": "5dd8359e9dbdf89f34d8cd885164b90f",
".git/objects/8a/29119ea659c4113282d15281fb73acaaddf685": "9673ed01320285acf227adfd965832ad",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8a/c25bc859a81c968ca691882702cafe92fc120f": "354730e5c0f209b53ea4b59d7e3c10db",
".git/objects/8a/f20b805ad4382a02c6a3a7ba1457fd6de627ff": "45b1e8d85513d53cdfb8c32fda24e0ec",
".git/objects/8b/f1a766f406b2736f580d7ef4a939fa28f13a8e": "1be8fa84011e0233b46de960fc46d3cf",
".git/objects/8d/168aa94339a2a365320e978533e31821fc1d21": "e43bd51e882681865b4f1cec5a2c32d0",
".git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
".git/objects/8e/9a1743abff473db146e93793326fb055edf8a0": "5fc174ea3bc5bcda091e4ab579e0d8e4",
".git/objects/90/65f0a2725f8efc23dcf58a4a1552de48cb428e": "1cb5348ef24d5b1674bcb13bcdb0b047",
".git/objects/92/5f2ce93d5c8dc7abc7d8bdb1287ab1d48c1554": "d8ce0a809557cd0c4311fd6f991fcb7a",
".git/objects/92/ad158dc64efd666fc590a1ca2d97bdd79f6944": "c9adc93c29cee5d8b1ea34bbb14afea7",
".git/objects/92/ca1136cbc3230f345b6ced05a34e401f0a88b9": "1882737a1287998975d7812525c29c60",
".git/objects/93/7b5d7e167112239496d5e7c1de7c9f8361511c": "f8024cb1db12ecadbc1e68f039a011fb",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/95/565982bbdff99273bf78fa8a2e30d9f80ad679": "cfcd088467140c1818984b44a0b81c66",
".git/objects/95/91deaea91d604eb320dd104e469d73db74181f": "e7988e39603a1bcd5d863281d54ee814",
".git/objects/97/42789b5a696b9a6543c5968465f9cf8862f3ea": "b7a63142c4981da2b828039703f5112c",
".git/objects/97/e2e0d06c4d33f8e8f84b1e88a9db241df5a12f": "d5f25e6b2d88c427dc2459e72b8b5cab",
".git/objects/97/f5d9ab0b7a43d8da4016fd525503375150426a": "f7846f36635f002983d819db086b8485",
".git/objects/9a/ba4f905613139919f977b012de761ae292354a": "5a8ded32b8c9cef19fe95a5e076a43f8",
".git/objects/a0/48f58e5699135b91869e2b37e04998b9e57f86": "558861af9f372504b6b99190c00b0fa9",
".git/objects/a3/4ffc4e036776adae293f1a70c0bea99d2a9f5c": "596972a0d996642c4598ba0c167d3adc",
".git/objects/a3/b4c41c429a383cbf94b41b0861bfdcf5dfc9e5": "0bffcd16531a0ce81a8b50d6e768026f",
".git/objects/a4/399da119d43fb86eac873ea838dae694fe1f20": "5e73078d134857240dc0ea0a0e25abc3",
".git/objects/a5/4e1b09e6d572956cb96fa92a8bcd9cc4cc817b": "bc99c0c17979e603f83ad2ecef08cf4d",
".git/objects/a6/27648e9b0e240a28bd5753560a0d9bee6d7527": "1048ecc9593b29e6faab7dad8993a832",
".git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
".git/objects/a8/6782305ff80ab030b0e46f19e4a100c60f1ff6": "f90ac8649b8c8fdda40c12d8afc59fc2",
".git/objects/a8/bddaa4fff677065bee038fc25fb7d0db336f72": "6bbb24ccab03dc37650bcb7f2a2ca8a1",
".git/objects/aa/1303ae7d87112ffa37044d71ceddb40b15639c": "fed77399260a479be67bcfc962a0e5c0",
".git/objects/ab/dd1a83969bb71270cde176537bbdbf5133a37e": "528220086ff7ec6afb9bd3d719edfc31",
".git/objects/ac/1dd0f9ba867740fbae340619aece90fed8fcd8": "182bbd892658a99918f6d8bbb6cfc2d6",
".git/objects/ad/7b32beb71baaf2dc54e20b56638e4fb8fa3aca": "36ae34260f534c95e827708451cbdbf4",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/ae/8fb65c0b5bd11ddf3a2fbeba25594ff5747eeb": "d43b0ee9108e17515fb9dfde49f69e0c",
".git/objects/af/803374814c57400efcec457269250f3ff4df6d": "f27ff2cd244db348842ec5f233b102d3",
".git/objects/af/85b1da83e5a19e031b53755465eba27124523b": "65459a12572cf30603b71ad371f5849c",
".git/objects/b6/b6683ad6a044bb87d133b148cce6dd34a917a1": "8351a34d3eef39b035e41f97343b0774",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b7/d09ee66acc28edfa7494737b3a625e50ee3b7f": "8c6f9d818659a40ee6d7d6e7c0db6b5f",
".git/objects/b7/e804a0cd9ae8f8a835c5e353808cc50b762ec8": "6736885a7b7b9f86e130b3c99c53bee1",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/bc/33bd6ae0cc407b9a18a2c7ff775e0fd654332f": "0a249e94c7f5a61b5dfc7748ed38a887",
".git/objects/bc/b970fcfbbe07adf52f7d257ab77b718a9f8e8a": "869dd12183e3db5a0a56a052bfbed87d",
".git/objects/bd/3ec181932252201389d879844c16dcf6ad228f": "a28414d4c3b29ef569c2b8d1e89cb9da",
".git/objects/c2/46fe93bcb81a17c5ef71aa09a252c1b237fdc4": "7dba900fbab22c3bfbe180b4d478b5ca",
".git/objects/c3/3fb722132dc6d5535ed9d32eab993932fdc82a": "5b2c6c52ff5efa41313211350fea3a9e",
".git/objects/c3/7130fb3a6215b065f72e9a36cda7ec941a2ef4": "404dffe895815d382ae078f68f3dccd9",
".git/objects/c4/4bf587e20d915d7711a07c143ec690ed018bfd": "9469d51f4519c0219f69ff9a71780c7f",
".git/objects/c5/d6c2f317ee06723fc5570e7429d82a40bbe6f4": "d497a3445b0494e7118202caa093f0a8",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/cc/e3ff22ff1ec7a65f964bc74e9b8587e614f2ab": "6023096b59ac9f0bfddfc24c1a5bd552",
".git/objects/d1/911c16912c4e7d5e62743567e8d4300c2f3bc4": "2b8e33bf518fdc9b5dae27ba715b3078",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d5/65822c5ed6c8a0cc00a41dc508061a4ca99b3e": "7bf5bd04e012037640787f0f3b805b1f",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d9/41e01d0d855a4190d61949776073a0a0a2a6b2": "d02a9d4681049c6fa1e09a62434145ec",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/d9/62c4d1c9e7467abf565748ec63d56f72df5bd8": "351fb026793bc97f57df95410de70e0d",
".git/objects/db/9807b17037779ecc58e36a4340663b80973edf": "dbf1b6ac3f472bac4768c7003aa3ba7b",
".git/objects/dc/5342f59e3b915dbb658519aa3698802a16991d": "a5472090883cce4f151ab81a272b70bb",
".git/objects/dd/83d574c902eb2534af3d0e80165fcb31c8a40a": "4b232c5836285097512d567e509a960a",
".git/objects/df/0ccc510dfbfd70c42cc3d8ee0e03a350086bad": "8f1e906fa8f796bba9013853d584709f",
".git/objects/df/2256e90dd768daf923bd211386f65fd7a28ac9": "35c129d450c200c3f493cdb11e57e273",
".git/objects/e2/0f1052958229bc738f6b83dc6150e104916d84": "52a68ddc68eea0a54c4aaf9fcc14d450",
".git/objects/e4/889bca750d0030d87609c517198c49ce859497": "ccd2a13e4be3a3817053d76a8fd9bb00",
".git/objects/e6/59d05a6d0e1654d0d7d8e0261433705ea557a3": "1861ceaa8e603dcf6754768bf1896039",
".git/objects/e6/6e4c84432e960a2b1d740e9ef1455ece895701": "97f8a5666fb2a203b6f2850ce8674eea",
".git/objects/e7/1cad1593ec8eebf332bb0ee4bdd31b85a0662f": "1c1d57d9a200f0f446160d9f872935fe",
".git/objects/e9/adad60e26baed57915e85a9d0a9b65b1c57824": "2493294e44e8e3739a3a42270b7febb3",
".git/objects/e9/c225cd807ae2c7fd8ee0f6bf36a8ce6da688ee": "8ad60438944d9af6cf7c8a90ca927c30",
".git/objects/eb/8fc9d4594689dd363a508905eac08e54cf09d3": "ec7879f8ba604b02540c9ff9d6507649",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ef/20ef8ab3effb2b85fdb97cdf36c929ae4be5e4": "b74183ce644b6c36a5b549f4187581ae",
".git/objects/ef/9cec98ead6b6971017d7b70b04fb819076913a": "82f3b1cb830654a656be8900ce395fdf",
".git/objects/ef/bc9c1a2ca1329d7baae50a06fcd3516fd16a8f": "49c52da12f997581f9af1d72b576288d",
".git/objects/ef/d75f1980bf6e42d548aed348507bb21f1e63ac": "2c572a8f16e6c168e155139bf29efb63",
".git/objects/f0/4e9ec0edd178c4d44539bd1149af3554c8f808": "7efb68aa9f05307bad7a40f3f740080e",
".git/objects/f1/1c762feabe00a7d5a6c801f888cee57534cfa6": "45335734b4d676f3e427ade6e45b7692",
".git/objects/f1/becd8512b314cf51ff709199a5d2a0dcd2c6c9": "98515960180878291eae3d0910b5ca70",
".git/objects/f2/34c19deb6aa5b83fc910326ce33d25b0a4eea9": "8ae3718c4400ca8392d526810fe9d1b6",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f3/75474fa2b6a2c60e67c020adff57789c46535e": "3b99641a946e25f0421426f1210d8139",
".git/objects/f4/e84f9eaadd1e93762d24adaa6c0173e8d064f3": "dcc1ef310667f5873f172ad90de63997",
".git/objects/f6/721074dae1bc299e230ef7868231f62d15169b": "644269610991df9c45898353ed136623",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/fa/df4c01776356f32c8614185e17cc3c2c8b8dec": "75d7afd0300f60b6f855e89c3c903b96",
".git/objects/fb/1efcdcdee01690f04070c43eb148983a367b16": "603fe2017facab788039f6b7fe7149a2",
".git/objects/fc/30b3e4242aca10f6f22cdcc53a891a737949cc": "dc3e5395d4a3aa386324b5ca584ff2ee",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/fe/571ab50cd4feee36fe3f9fc57cf0c50ff0e2bc": "115d149227d1069547282d9d6ef0ed09",
".git/objects/pack/pack-f4d0230d183e552cb013d6dd3fe7df4a4b7350ca.idx": "cec01f9e92638d89bd3383c1c61eff72",
".git/objects/pack/pack-f4d0230d183e552cb013d6dd3fe7df4a4b7350ca.pack": "a7a844159080910d3ffbf75bac346bfe",
".git/objects/pack/pack-f4d0230d183e552cb013d6dd3fe7df4a4b7350ca.rev": "46728bd5560b8b8eae3308b9285873d6",
".git/ORIG_HEAD": "16ac771f286da02b7c062806d41a1458",
".git/refs/heads/main": "16ac771f286da02b7c062806d41a1458",
".git/refs/remotes/origin/gh-pages": "16ac771f286da02b7c062806d41a1458",
".git/refs/remotes/origin/main": "58685116d1c509853808f838e65ba65f",
"assets/AssetManifest.bin": "6867382e696c69e14055aa29c98c3996",
"assets/AssetManifest.bin.json": "1bab74c5b085e5fd6b20c0339fcc2f32",
"assets/assets/data.json": "7bf38aebad2ba1fbf6243fe552b91510",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "86400e620ab97ddd175fd4a44b0fa100",
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
"flutter_bootstrap.js": "78261e27ec05b98eadf4e08fe6141948",
"icons/Icon-192.png": "d6e530b590ecd87177f3db22bcc7abc1",
"icons/Icon-512.png": "f23437636b23eac7fde06e06307477b8",
"icons/Icon-maskable-192.png": "d6e530b590ecd87177f3db22bcc7abc1",
"icons/Icon-maskable-512.png": "f23437636b23eac7fde06e06307477b8",
"index.html": "c83ae7a97f1218c534b70af8c27064f7",
"/": "c83ae7a97f1218c534b70af8c27064f7",
"main.dart.js": "abb12b0a136ecd87b2c6e92e8a76515b",
"main.dart.mjs": "9a8d066f3ddaa273a53797e39a053158",
"main.dart.wasm": "7fc3fb763b6803be0cb7515492cbe018",
"manifest.json": "03213b3d470b28b9fd5fa78ebd963f84",
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
