// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It should return a JS Array containing 2 elements. The first
  //   should be the bytes for the wasm module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The second
  //   should be the result of using the JS 'import' API on the js file path.
  async instantiate(additionalImports, {loadDeferredWasm, loadDynamicModule} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _4: (o, c) => o instanceof c,
      _5: o => Object.keys(o),
      _36: x0 => new Array(x0),
      _38: x0 => x0.length,
      _40: (x0,x1) => x0[x1],
      _41: (x0,x1,x2) => { x0[x1] = x2 },
      _43: x0 => new Promise(x0),
      _45: (x0,x1,x2) => new DataView(x0,x1,x2),
      _47: x0 => new Int8Array(x0),
      _48: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _49: x0 => new Uint8Array(x0),
      _51: x0 => new Uint8ClampedArray(x0),
      _53: x0 => new Int16Array(x0),
      _55: x0 => new Uint16Array(x0),
      _57: x0 => new Int32Array(x0),
      _59: x0 => new Uint32Array(x0),
      _61: x0 => new Float32Array(x0),
      _63: x0 => new Float64Array(x0),
      _65: (x0,x1,x2) => x0.call(x1,x2),
      _70: (decoder, codeUnits) => decoder.decode(codeUnits),
      _71: () => new TextDecoder("utf-8", {fatal: true}),
      _72: () => new TextDecoder("utf-8", {fatal: false}),
      _73: (s) => +s,
      _74: x0 => new Uint8Array(x0),
      _75: (x0,x1,x2) => x0.set(x1,x2),
      _76: (x0,x1) => x0.transferFromImageBitmap(x1),
      _78: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._78(f,arguments.length,x0) }),
      _79: x0 => new window.FinalizationRegistry(x0),
      _80: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _81: (x0,x1) => x0.unregister(x1),
      _82: (x0,x1,x2) => x0.slice(x1,x2),
      _83: (x0,x1) => x0.decode(x1),
      _84: (x0,x1) => x0.segment(x1),
      _85: () => new TextDecoder(),
      _86: (x0,x1) => x0.get(x1),
      _87: x0 => x0.buffer,
      _88: x0 => x0.wasmMemory,
      _89: () => globalThis.window._flutter_skwasmInstance,
      _90: x0 => x0.rasterStartMilliseconds,
      _91: x0 => x0.rasterEndMilliseconds,
      _92: x0 => x0.imageBitmaps,
      _196: x0 => x0.stopPropagation(),
      _197: x0 => x0.preventDefault(),
      _199: x0 => x0.remove(),
      _200: (x0,x1) => x0.append(x1),
      _201: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _246: x0 => x0.unlock(),
      _247: x0 => x0.getReader(),
      _248: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _249: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _250: (x0,x1) => x0.item(x1),
      _251: x0 => x0.next(),
      _252: x0 => x0.now(),
      _253: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._253(f,arguments.length,x0) }),
      _254: (x0,x1) => x0.addListener(x1),
      _255: (x0,x1) => x0.removeListener(x1),
      _256: (x0,x1) => x0.matchMedia(x1),
      _257: (x0,x1) => x0.revokeObjectURL(x1),
      _258: x0 => x0.close(),
      _259: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _260: x0 => new window.ImageDecoder(x0),
      _261: x0 => ({frameIndex: x0}),
      _262: (x0,x1) => x0.decode(x1),
      _263: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._263(f,arguments.length,x0) }),
      _264: (x0,x1) => x0.getModifierState(x1),
      _265: (x0,x1) => x0.removeProperty(x1),
      _266: (x0,x1) => x0.prepend(x1),
      _267: x0 => new Intl.Locale(x0),
      _268: x0 => x0.disconnect(),
      _269: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._269(f,arguments.length,x0) }),
      _270: (x0,x1) => x0.getAttribute(x1),
      _271: (x0,x1) => x0.contains(x1),
      _272: (x0,x1) => x0.querySelector(x1),
      _273: x0 => x0.blur(),
      _274: x0 => x0.hasFocus(),
      _275: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _276: (x0,x1) => x0.hasAttribute(x1),
      _277: (x0,x1) => x0.getModifierState(x1),
      _278: (x0,x1) => x0.createTextNode(x1),
      _279: (x0,x1) => x0.appendChild(x1),
      _280: (x0,x1) => x0.removeAttribute(x1),
      _281: x0 => x0.getBoundingClientRect(),
      _282: (x0,x1) => x0.observe(x1),
      _283: x0 => x0.disconnect(),
      _284: (x0,x1) => x0.closest(x1),
      _707: () => globalThis.window.flutterConfiguration,
      _709: x0 => x0.assetBase,
      _714: x0 => x0.canvasKitMaximumSurfaces,
      _715: x0 => x0.debugShowSemanticsNodes,
      _716: x0 => x0.hostElement,
      _717: x0 => x0.multiViewEnabled,
      _718: x0 => x0.nonce,
      _720: x0 => x0.fontFallbackBaseUrl,
      _730: x0 => x0.console,
      _731: x0 => x0.devicePixelRatio,
      _732: x0 => x0.document,
      _733: x0 => x0.history,
      _734: x0 => x0.innerHeight,
      _735: x0 => x0.innerWidth,
      _736: x0 => x0.location,
      _737: x0 => x0.navigator,
      _738: x0 => x0.visualViewport,
      _739: x0 => x0.performance,
      _741: x0 => x0.URL,
      _743: (x0,x1) => x0.getComputedStyle(x1),
      _744: x0 => x0.screen,
      _745: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._745(f,arguments.length,x0) }),
      _746: (x0,x1) => x0.requestAnimationFrame(x1),
      _751: (x0,x1) => x0.warn(x1),
      _753: (x0,x1) => x0.debug(x1),
      _754: x0 => globalThis.parseFloat(x0),
      _755: () => globalThis.window,
      _756: () => globalThis.Intl,
      _757: () => globalThis.Symbol,
      _758: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      _760: x0 => x0.clipboard,
      _761: x0 => x0.maxTouchPoints,
      _762: x0 => x0.vendor,
      _763: x0 => x0.language,
      _764: x0 => x0.platform,
      _765: x0 => x0.userAgent,
      _766: (x0,x1) => x0.vibrate(x1),
      _767: x0 => x0.languages,
      _768: x0 => x0.documentElement,
      _769: (x0,x1) => x0.querySelector(x1),
      _772: (x0,x1) => x0.createElement(x1),
      _775: (x0,x1) => x0.createEvent(x1),
      _776: x0 => x0.activeElement,
      _779: x0 => x0.head,
      _780: x0 => x0.body,
      _782: (x0,x1) => { x0.title = x1 },
      _785: x0 => x0.visibilityState,
      _786: () => globalThis.document,
      _787: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._787(f,arguments.length,x0) }),
      _788: (x0,x1) => x0.dispatchEvent(x1),
      _796: x0 => x0.target,
      _798: x0 => x0.timeStamp,
      _799: x0 => x0.type,
      _801: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _808: x0 => x0.firstChild,
      _812: x0 => x0.parentElement,
      _814: (x0,x1) => { x0.textContent = x1 },
      _815: x0 => x0.parentNode,
      _816: x0 => x0.nextSibling,
      _817: (x0,x1) => x0.removeChild(x1),
      _818: x0 => x0.isConnected,
      _826: x0 => x0.clientHeight,
      _827: x0 => x0.clientWidth,
      _828: x0 => x0.offsetHeight,
      _829: x0 => x0.offsetWidth,
      _830: x0 => x0.id,
      _831: (x0,x1) => { x0.id = x1 },
      _834: (x0,x1) => { x0.spellcheck = x1 },
      _835: x0 => x0.tagName,
      _836: x0 => x0.style,
      _838: (x0,x1) => x0.querySelectorAll(x1),
      _839: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _840: (x0,x1) => { x0.tabIndex = x1 },
      _841: x0 => x0.tabIndex,
      _842: (x0,x1) => x0.focus(x1),
      _843: x0 => x0.scrollTop,
      _844: (x0,x1) => { x0.scrollTop = x1 },
      _845: x0 => x0.scrollLeft,
      _846: (x0,x1) => { x0.scrollLeft = x1 },
      _847: x0 => x0.classList,
      _849: (x0,x1) => { x0.className = x1 },
      _851: (x0,x1) => x0.getElementsByClassName(x1),
      _852: x0 => x0.click(),
      _853: (x0,x1) => x0.attachShadow(x1),
      _856: x0 => x0.computedStyleMap(),
      _857: (x0,x1) => x0.get(x1),
      _863: (x0,x1) => x0.getPropertyValue(x1),
      _864: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _865: x0 => x0.offsetLeft,
      _866: x0 => x0.offsetTop,
      _867: x0 => x0.offsetParent,
      _869: (x0,x1) => { x0.name = x1 },
      _870: x0 => x0.content,
      _871: (x0,x1) => { x0.content = x1 },
      _875: (x0,x1) => { x0.src = x1 },
      _876: x0 => x0.naturalWidth,
      _877: x0 => x0.naturalHeight,
      _881: (x0,x1) => { x0.crossOrigin = x1 },
      _883: (x0,x1) => { x0.decoding = x1 },
      _884: x0 => x0.decode(),
      _889: (x0,x1) => { x0.nonce = x1 },
      _894: (x0,x1) => { x0.width = x1 },
      _896: (x0,x1) => { x0.height = x1 },
      _899: (x0,x1) => x0.getContext(x1),
      _960: x0 => x0.width,
      _961: x0 => x0.height,
      _963: (x0,x1) => x0.fetch(x1),
      _964: x0 => x0.status,
      _965: x0 => x0.headers,
      _966: x0 => x0.body,
      _967: x0 => x0.arrayBuffer(),
      _970: x0 => x0.read(),
      _971: x0 => x0.value,
      _972: x0 => x0.done,
      _979: x0 => x0.name,
      _980: x0 => x0.x,
      _981: x0 => x0.y,
      _984: x0 => x0.top,
      _985: x0 => x0.right,
      _986: x0 => x0.bottom,
      _987: x0 => x0.left,
      _997: x0 => x0.height,
      _998: x0 => x0.width,
      _999: x0 => x0.scale,
      _1000: (x0,x1) => { x0.value = x1 },
      _1003: (x0,x1) => { x0.placeholder = x1 },
      _1005: (x0,x1) => { x0.name = x1 },
      _1006: x0 => x0.selectionDirection,
      _1007: x0 => x0.selectionStart,
      _1008: x0 => x0.selectionEnd,
      _1011: x0 => x0.value,
      _1013: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1014: x0 => x0.readText(),
      _1015: (x0,x1) => x0.writeText(x1),
      _1017: x0 => x0.altKey,
      _1018: x0 => x0.code,
      _1019: x0 => x0.ctrlKey,
      _1020: x0 => x0.key,
      _1021: x0 => x0.keyCode,
      _1022: x0 => x0.location,
      _1023: x0 => x0.metaKey,
      _1024: x0 => x0.repeat,
      _1025: x0 => x0.shiftKey,
      _1026: x0 => x0.isComposing,
      _1028: x0 => x0.state,
      _1029: (x0,x1) => x0.go(x1),
      _1031: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _1032: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _1033: x0 => x0.pathname,
      _1034: x0 => x0.search,
      _1035: x0 => x0.hash,
      _1039: x0 => x0.state,
      _1042: (x0,x1) => x0.createObjectURL(x1),
      _1044: x0 => new Blob(x0),
      _1046: x0 => new MutationObserver(x0),
      _1047: (x0,x1,x2) => x0.observe(x1,x2),
      _1048: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1048(f,arguments.length,x0,x1) }),
      _1051: x0 => x0.attributeName,
      _1052: x0 => x0.type,
      _1053: x0 => x0.matches,
      _1054: x0 => x0.matches,
      _1058: x0 => x0.relatedTarget,
      _1060: x0 => x0.clientX,
      _1061: x0 => x0.clientY,
      _1062: x0 => x0.offsetX,
      _1063: x0 => x0.offsetY,
      _1066: x0 => x0.button,
      _1067: x0 => x0.buttons,
      _1068: x0 => x0.ctrlKey,
      _1072: x0 => x0.pointerId,
      _1073: x0 => x0.pointerType,
      _1074: x0 => x0.pressure,
      _1075: x0 => x0.tiltX,
      _1076: x0 => x0.tiltY,
      _1077: x0 => x0.getCoalescedEvents(),
      _1080: x0 => x0.deltaX,
      _1081: x0 => x0.deltaY,
      _1082: x0 => x0.wheelDeltaX,
      _1083: x0 => x0.wheelDeltaY,
      _1084: x0 => x0.deltaMode,
      _1091: x0 => x0.changedTouches,
      _1094: x0 => x0.clientX,
      _1095: x0 => x0.clientY,
      _1098: x0 => x0.data,
      _1101: (x0,x1) => { x0.disabled = x1 },
      _1103: (x0,x1) => { x0.type = x1 },
      _1104: (x0,x1) => { x0.max = x1 },
      _1105: (x0,x1) => { x0.min = x1 },
      _1106: x0 => x0.value,
      _1107: (x0,x1) => { x0.value = x1 },
      _1108: x0 => x0.disabled,
      _1109: (x0,x1) => { x0.disabled = x1 },
      _1111: (x0,x1) => { x0.placeholder = x1 },
      _1112: (x0,x1) => { x0.name = x1 },
      _1115: (x0,x1) => { x0.autocomplete = x1 },
      _1116: x0 => x0.selectionDirection,
      _1117: x0 => x0.selectionStart,
      _1119: x0 => x0.selectionEnd,
      _1122: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1123: (x0,x1) => x0.add(x1),
      _1126: (x0,x1) => { x0.noValidate = x1 },
      _1127: (x0,x1) => { x0.method = x1 },
      _1128: (x0,x1) => { x0.action = x1 },
      _1154: x0 => x0.orientation,
      _1155: x0 => x0.width,
      _1156: x0 => x0.height,
      _1157: (x0,x1) => x0.lock(x1),
      _1176: x0 => new ResizeObserver(x0),
      _1179: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1179(f,arguments.length,x0,x1) }),
      _1187: x0 => x0.length,
      _1188: x0 => x0.iterator,
      _1189: x0 => x0.Segmenter,
      _1190: x0 => x0.v8BreakIterator,
      _1191: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1194: x0 => x0.language,
      _1195: x0 => x0.script,
      _1196: x0 => x0.region,
      _1214: x0 => x0.done,
      _1215: x0 => x0.value,
      _1216: x0 => x0.index,
      _1220: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1221: (x0,x1) => x0.adoptText(x1),
      _1222: x0 => x0.first(),
      _1223: x0 => x0.next(),
      _1224: x0 => x0.current(),
      _1238: x0 => x0.hostElement,
      _1239: x0 => x0.viewConstraints,
      _1242: x0 => x0.maxHeight,
      _1243: x0 => x0.maxWidth,
      _1244: x0 => x0.minHeight,
      _1245: x0 => x0.minWidth,
      _1246: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1246(f,arguments.length,x0) }),
      _1247: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1247(f,arguments.length,x0) }),
      _1248: (x0,x1) => ({addView: x0,removeView: x1}),
      _1251: x0 => x0.loader,
      _1252: () => globalThis._flutter,
      _1253: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1254: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1254(f,arguments.length,x0) }),
      _1255: f => finalizeWrapper(f, function() { return dartInstance.exports._1255(f,arguments.length) }),
      _1256: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1259: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1259(f,arguments.length,x0) }),
      _1260: x0 => ({runApp: x0}),
      _1262: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1262(f,arguments.length,x0,x1) }),
      _1263: x0 => x0.length,
      _1264: () => globalThis.window.ImageDecoder,
      _1265: x0 => x0.tracks,
      _1267: x0 => x0.completed,
      _1269: x0 => x0.image,
      _1275: x0 => x0.displayWidth,
      _1276: x0 => x0.displayHeight,
      _1277: x0 => x0.duration,
      _1280: x0 => x0.ready,
      _1281: x0 => x0.selectedTrack,
      _1282: x0 => x0.repetitionCount,
      _1283: x0 => x0.frameCount,
      _1329: (x0,x1,x2,x3,x4,x5) => x0.drawImage(x1,x2,x3,x4,x5),
      _1330: x0 => globalThis.URL.createObjectURL(x0),
      _1336: (x0,x1) => x0.querySelector(x1),
      _1337: (x0,x1) => x0.createElement(x1),
      _1338: (x0,x1) => x0.append(x1),
      _1339: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1342: (x0,x1) => x0.getUserMedia(x1),
      _1343: x0 => x0.getSupportedConstraints(),
      _1344: x0 => x0.getVideoTracks(),
      _1345: x0 => x0.getCapabilities(),
      _1346: x0 => x0.getSettings(),
      _1347: (x0,x1,x2) => x0.setProperty(x1,x2),
      _1348: x0 => x0.play(),
      _1350: x0 => x0.getTracks(),
      _1351: x0 => x0.stop(),
      _1352: (x0,x1,x2) => x0.translate(x1,x2),
      _1353: (x0,x1,x2) => x0.scale(x1,x2),
      _1354: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1354(f,arguments.length,x0) }),
      _1355: (x0,x1,x2) => x0.toBlob(x1,x2),
      _1356: x0 => ({torch: x0}),
      _1357: (x0,x1) => x0.applyConstraints(x1),
      _1371: x0 => x0.load(),
      _1372: x0 => globalThis.MediaRecorder.isTypeSupported(x0),
      _1373: x0 => ({type: x0}),
      _1374: (x0,x1) => new Blob(x0,x1),
      _1375: x0 => x0.enumerateDevices(),
      _1376: x0 => new Event(x0),
      _1387: x0 => x0.toArray(),
      _1388: x0 => x0.toUint8Array(),
      _1389: x0 => ({serverTimestamps: x0}),
      _1390: x0 => ({source: x0}),
      _1391: x0 => ({merge: x0}),
      _1393: x0 => new firebase_firestore.FieldPath(x0),
      _1394: (x0,x1) => new firebase_firestore.FieldPath(x0,x1),
      _1395: (x0,x1,x2) => new firebase_firestore.FieldPath(x0,x1,x2),
      _1396: (x0,x1,x2,x3) => new firebase_firestore.FieldPath(x0,x1,x2,x3),
      _1397: (x0,x1,x2,x3,x4) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4),
      _1398: (x0,x1,x2,x3,x4,x5) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5),
      _1399: (x0,x1,x2,x3,x4,x5,x6) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6),
      _1400: (x0,x1,x2,x3,x4,x5,x6,x7) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7),
      _1401: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8),
      _1402: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9),
      _1403: () => globalThis.firebase_firestore.documentId(),
      _1404: (x0,x1) => new firebase_firestore.GeoPoint(x0,x1),
      _1405: x0 => globalThis.firebase_firestore.vector(x0),
      _1406: x0 => globalThis.firebase_firestore.Bytes.fromUint8Array(x0),
      _1408: (x0,x1) => globalThis.firebase_firestore.collection(x0,x1),
      _1410: (x0,x1) => globalThis.firebase_firestore.doc(x0,x1),
      _1415: x0 => x0.call(),
      _1444: x0 => globalThis.firebase_firestore.deleteDoc(x0),
      _1445: x0 => globalThis.firebase_firestore.getDoc(x0),
      _1446: x0 => globalThis.firebase_firestore.getDocFromServer(x0),
      _1447: x0 => globalThis.firebase_firestore.getDocFromCache(x0),
      _1453: (x0,x1,x2) => globalThis.firebase_firestore.setDoc(x0,x1,x2),
      _1454: (x0,x1) => globalThis.firebase_firestore.setDoc(x0,x1),
      _1455: (x0,x1) => globalThis.firebase_firestore.query(x0,x1),
      _1456: x0 => globalThis.firebase_firestore.getDocs(x0),
      _1457: x0 => globalThis.firebase_firestore.getDocsFromServer(x0),
      _1458: x0 => globalThis.firebase_firestore.getDocsFromCache(x0),
      _1459: x0 => globalThis.firebase_firestore.limit(x0),
      _1460: x0 => globalThis.firebase_firestore.limitToLast(x0),
      _1463: (x0,x1) => globalThis.firebase_firestore.orderBy(x0,x1),
      _1465: (x0,x1,x2) => globalThis.firebase_firestore.where(x0,x1,x2),
      _1471: (x0,x1) => x0.data(x1),
      _1475: x0 => x0.docChanges(),
      _1484: () => globalThis.firebase_firestore.serverTimestamp(),
      _1492: (x0,x1) => globalThis.firebase_firestore.getFirestore(x0,x1),
      _1494: x0 => globalThis.firebase_firestore.Timestamp.fromMillis(x0),
      _1495: f => finalizeWrapper(f, function() { return dartInstance.exports._1495(f,arguments.length) }),
      _1512: () => globalThis.firebase_firestore.or,
      _1513: () => globalThis.firebase_firestore.and,
      _1518: x0 => x0.path,
      _1521: () => globalThis.firebase_firestore.GeoPoint,
      _1522: x0 => x0.latitude,
      _1523: x0 => x0.longitude,
      _1525: () => globalThis.firebase_firestore.VectorValue,
      _1526: () => globalThis.firebase_firestore.Bytes,
      _1529: x0 => x0.type,
      _1531: x0 => x0.doc,
      _1533: x0 => x0.oldIndex,
      _1535: x0 => x0.newIndex,
      _1537: () => globalThis.firebase_firestore.DocumentReference,
      _1541: x0 => x0.path,
      _1550: x0 => x0.metadata,
      _1551: x0 => x0.ref,
      _1556: x0 => x0.docs,
      _1558: x0 => x0.metadata,
      _1562: () => globalThis.firebase_firestore.Timestamp,
      _1563: x0 => x0.seconds,
      _1564: x0 => x0.nanoseconds,
      _1601: x0 => x0.hasPendingWrites,
      _1603: x0 => x0.fromCache,
      _1610: x0 => x0.source,
      _1615: () => globalThis.firebase_firestore.startAfter,
      _1616: () => globalThis.firebase_firestore.startAt,
      _1617: () => globalThis.firebase_firestore.endBefore,
      _1618: () => globalThis.firebase_firestore.endAt,
      _1627: (x0,x1) => x0.createElement(x1),
      _1633: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1643: (x0,x1) => x0.item(x1),
      _1644: (x0,x1) => x0.getAttribute(x1),
      _1646: (x0,x1) => x0.initialize(x1),
      _1647: (x0,x1) => x0.initTokenClient(x1),
      _1648: (x0,x1) => x0.initCodeClient(x1),
      _1650: (x0,x1) => x0.warn(x1),
      _1651: x0 => x0.disableAutoSelect(),
      _1652: x0 => x0.decode(),
      _1653: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1654: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1655: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1655(f,arguments.length,x0) }),
      _1656: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1656(f,arguments.length,x0) }),
      _1657: x0 => x0.send(),
      _1658: () => new XMLHttpRequest(),
      _1679: x0 => x0.toJSON(),
      _1680: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1680(f,arguments.length,x0) }),
      _1681: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1681(f,arguments.length,x0) }),
      _1682: (x0,x1,x2) => x0.onAuthStateChanged(x1,x2),
      _1683: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1683(f,arguments.length,x0) }),
      _1684: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1684(f,arguments.length,x0) }),
      _1685: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1685(f,arguments.length,x0) }),
      _1686: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1686(f,arguments.length,x0) }),
      _1687: (x0,x1,x2) => x0.onIdTokenChanged(x1,x2),
      _1698: (x0,x1) => globalThis.firebase_auth.signInWithCredential(x0,x1),
      _1706: x0 => x0.signOut(),
      _1707: (x0,x1) => globalThis.firebase_auth.connectAuthEmulator(x0,x1),
      _1725: (x0,x1) => globalThis.firebase_auth.GoogleAuthProvider.credential(x0,x1),
      _1726: x0 => new firebase_auth.OAuthProvider(x0),
      _1729: (x0,x1) => x0.credential(x1),
      _1730: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromResult(x0),
      _1745: x0 => globalThis.firebase_auth.getAdditionalUserInfo(x0),
      _1746: (x0,x1,x2) => ({errorMap: x0,persistence: x1,popupRedirectResolver: x2}),
      _1747: (x0,x1) => globalThis.firebase_auth.initializeAuth(x0,x1),
      _1748: (x0,x1,x2) => ({accessToken: x0,idToken: x1,rawNonce: x2}),
      _1753: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromError(x0),
      _1768: () => globalThis.firebase_auth.debugErrorMap,
      _1771: () => globalThis.firebase_auth.browserSessionPersistence,
      _1773: () => globalThis.firebase_auth.browserLocalPersistence,
      _1775: () => globalThis.firebase_auth.indexedDBLocalPersistence,
      _1778: x0 => globalThis.firebase_auth.multiFactor(x0),
      _1779: (x0,x1) => globalThis.firebase_auth.getMultiFactorResolver(x0,x1),
      _1781: x0 => x0.currentUser,
      _1795: x0 => x0.displayName,
      _1796: x0 => x0.email,
      _1797: x0 => x0.phoneNumber,
      _1798: x0 => x0.photoURL,
      _1799: x0 => x0.providerId,
      _1800: x0 => x0.uid,
      _1801: x0 => x0.emailVerified,
      _1802: x0 => x0.isAnonymous,
      _1803: x0 => x0.providerData,
      _1804: x0 => x0.refreshToken,
      _1805: x0 => x0.tenantId,
      _1806: x0 => x0.metadata,
      _1808: x0 => x0.providerId,
      _1809: x0 => x0.signInMethod,
      _1810: x0 => x0.accessToken,
      _1811: x0 => x0.idToken,
      _1812: x0 => x0.secret,
      _1823: x0 => x0.creationTime,
      _1824: x0 => x0.lastSignInTime,
      _1829: x0 => x0.code,
      _1831: x0 => x0.message,
      _1843: x0 => x0.email,
      _1844: x0 => x0.phoneNumber,
      _1845: x0 => x0.tenantId,
      _1868: x0 => x0.user,
      _1871: x0 => x0.providerId,
      _1872: x0 => x0.profile,
      _1873: x0 => x0.username,
      _1874: x0 => x0.isNewUser,
      _1877: () => globalThis.firebase_auth.browserPopupRedirectResolver,
      _1882: x0 => x0.displayName,
      _1883: x0 => x0.enrollmentTime,
      _1884: x0 => x0.factorId,
      _1885: x0 => x0.uid,
      _1887: x0 => x0.hints,
      _1888: x0 => x0.session,
      _1890: x0 => x0.phoneNumber,
      _1902: (x0,x1) => x0.getItem(x1),
      _1907: (x0,x1) => x0.appendChild(x1),
      _1910: (x0,x1) => ({video: x0,audio: x1}),
      _1912: (x0,x1,x2) => x0.setItem(x1,x2),
      _1925: (x0,x1,x2,x3,x4,x5,x6,x7) => ({apiKey: x0,authDomain: x1,databaseURL: x2,projectId: x3,storageBucket: x4,messagingSenderId: x5,measurementId: x6,appId: x7}),
      _1926: (x0,x1) => globalThis.firebase_core.initializeApp(x0,x1),
      _1927: x0 => globalThis.firebase_core.getApp(x0),
      _1928: () => globalThis.firebase_core.getApp(),
      _1930: () => globalThis.firebase_core.SDK_VERSION,
      _1936: x0 => x0.apiKey,
      _1938: x0 => x0.authDomain,
      _1940: x0 => x0.databaseURL,
      _1942: x0 => x0.projectId,
      _1944: x0 => x0.storageBucket,
      _1946: x0 => x0.messagingSenderId,
      _1948: x0 => x0.measurementId,
      _1950: x0 => x0.appId,
      _1952: x0 => x0.name,
      _1953: x0 => x0.options,
      _1954: (x0,x1) => x0.debug(x1),
      _1955: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1955(f,arguments.length,x0) }),
      _1956: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1956(f,arguments.length,x0,x1) }),
      _1957: (x0,x1) => ({createScript: x0,createScriptURL: x1}),
      _1958: (x0,x1,x2) => x0.createPolicy(x1,x2),
      _1959: (x0,x1) => x0.createScriptURL(x1),
      _1960: (x0,x1,x2) => x0.createScript(x1,x2),
      _1961: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1961(f,arguments.length,x0) }),
      _1963: Date.now,
      _1965: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1966: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1967: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _1968: () => typeof dartUseDateNowForTicks !== "undefined",
      _1969: () => 1000 * performance.now(),
      _1970: () => Date.now(),
      _1971: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _1972: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _1973: () => new WeakMap(),
      _1974: (map, o) => map.get(o),
      _1975: (map, o, v) => map.set(o, v),
      _1976: x0 => new WeakRef(x0),
      _1977: x0 => x0.deref(),
      _1984: () => globalThis.WeakRef,
      _1987: s => JSON.stringify(s),
      _1988: s => printToConsole(s),
      _1989: (o, p, r) => o.replaceAll(p, () => r),
      _1990: (o, p, r) => o.replace(p, () => r),
      _1991: Function.prototype.call.bind(String.prototype.toLowerCase),
      _1992: s => s.toUpperCase(),
      _1993: s => s.trim(),
      _1994: s => s.trimLeft(),
      _1995: s => s.trimRight(),
      _1996: (string, times) => string.repeat(times),
      _1997: Function.prototype.call.bind(String.prototype.indexOf),
      _1998: (s, p, i) => s.lastIndexOf(p, i),
      _1999: (string, token) => string.split(token),
      _2000: Object.is,
      _2001: o => o instanceof Array,
      _2002: (a, i) => a.push(i),
      _2006: a => a.pop(),
      _2007: (a, i) => a.splice(i, 1),
      _2008: (a, s) => a.join(s),
      _2009: (a, s, e) => a.slice(s, e),
      _2011: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _2012: a => a.length,
      _2014: (a, i) => a[i],
      _2015: (a, i, v) => a[i] = v,
      _2017: o => {
        if (o instanceof ArrayBuffer) return 0;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 1;
        }
        return 2;
      },
      _2018: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _2020: o => o instanceof Uint8Array,
      _2021: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _2022: o => o instanceof Int8Array,
      _2023: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _2024: o => o instanceof Uint8ClampedArray,
      _2025: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _2026: o => o instanceof Uint16Array,
      _2027: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _2028: o => o instanceof Int16Array,
      _2029: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _2030: o => o instanceof Uint32Array,
      _2031: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _2032: o => o instanceof Int32Array,
      _2033: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _2035: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _2036: o => o instanceof Float32Array,
      _2037: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _2038: o => o instanceof Float64Array,
      _2039: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _2040: (t, s) => t.set(s),
      _2041: l => new DataView(new ArrayBuffer(l)),
      _2042: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _2043: o => o.byteLength,
      _2044: o => o.buffer,
      _2045: o => o.byteOffset,
      _2046: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _2047: (b, o) => new DataView(b, o),
      _2048: (b, o, l) => new DataView(b, o, l),
      _2049: Function.prototype.call.bind(DataView.prototype.getUint8),
      _2050: Function.prototype.call.bind(DataView.prototype.setUint8),
      _2051: Function.prototype.call.bind(DataView.prototype.getInt8),
      _2052: Function.prototype.call.bind(DataView.prototype.setInt8),
      _2053: Function.prototype.call.bind(DataView.prototype.getUint16),
      _2054: Function.prototype.call.bind(DataView.prototype.setUint16),
      _2055: Function.prototype.call.bind(DataView.prototype.getInt16),
      _2056: Function.prototype.call.bind(DataView.prototype.setInt16),
      _2057: Function.prototype.call.bind(DataView.prototype.getUint32),
      _2058: Function.prototype.call.bind(DataView.prototype.setUint32),
      _2059: Function.prototype.call.bind(DataView.prototype.getInt32),
      _2060: Function.prototype.call.bind(DataView.prototype.setInt32),
      _2063: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _2064: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _2065: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _2066: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _2067: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _2068: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _2081: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _2082: (handle) => clearTimeout(handle),
      _2083: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _2084: (handle) => clearInterval(handle),
      _2085: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _2086: () => Date.now(),
      _2087: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _2088: (x0,x1) => x0.exec(x1),
      _2089: (x0,x1) => x0.test(x1),
      _2090: x0 => x0.pop(),
      _2092: o => o === undefined,
      _2094: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _2096: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _2097: o => o instanceof RegExp,
      _2098: (l, r) => l === r,
      _2099: o => o,
      _2100: o => o,
      _2101: o => o,
      _2102: b => !!b,
      _2103: o => o.length,
      _2105: (o, i) => o[i],
      _2106: f => f.dartFunction,
      _2107: () => ({}),
      _2108: () => [],
      _2110: () => globalThis,
      _2111: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _2112: (o, p) => p in o,
      _2113: (o, p) => o[p],
      _2114: (o, p, v) => o[p] = v,
      _2115: (o, m, a) => o[m].apply(o, a),
      _2117: o => String(o),
      _2118: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _2119: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2119(f,arguments.length,x0) }),
      _2120: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._2120(f,arguments.length,x0,x1) }),
      _2121: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      _2122: o => [o],
      _2123: (o0, o1) => [o0, o1],
      _2124: (o0, o1, o2) => [o0, o1, o2],
      _2125: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _2126: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2127: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2128: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2129: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2130: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2131: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2132: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2133: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2134: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2135: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2136: x0 => new ArrayBuffer(x0),
      _2137: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _2139: x0 => x0.index,
      _2140: x0 => x0.groups,
      _2141: x0 => x0.flags,
      _2142: x0 => x0.multiline,
      _2143: x0 => x0.ignoreCase,
      _2144: x0 => x0.unicode,
      _2145: x0 => x0.dotAll,
      _2146: (x0,x1) => { x0.lastIndex = x1 },
      _2147: (o, p) => p in o,
      _2148: (o, p) => o[p],
      _2149: (o, p, v) => o[p] = v,
      _2150: (o, p) => delete o[p],
      _2151: () => new XMLHttpRequest(),
      _2152: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _2156: x0 => x0.send(),
      _2158: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2158(f,arguments.length,x0) }),
      _2159: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2159(f,arguments.length,x0) }),
      _2160: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _2161: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _2169: () => new FileReader(),
      _2170: (x0,x1) => x0.readAsArrayBuffer(x1),
      _2173: () => new AbortController(),
      _2174: x0 => x0.abort(),
      _2175: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _2176: (x0,x1) => globalThis.fetch(x0,x1),
      _2177: (x0,x1) => x0.get(x1),
      _2178: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._2178(f,arguments.length,x0,x1,x2) }),
      _2179: (x0,x1) => x0.forEach(x1),
      _2180: x0 => x0.getReader(),
      _2181: x0 => x0.cancel(),
      _2182: x0 => x0.read(),
      _2183: x0 => x0.trustedTypes,
      _2184: (x0,x1) => { x0.src = x1 },
      _2185: (x0,x1) => x0.createScriptURL(x1),
      _2186: x0 => x0.nonce,
      _2187: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2187(f,arguments.length,x0) }),
      _2188: x0 => ({createScriptURL: x0}),
      _2189: (x0,x1) => x0.querySelectorAll(x1),
      _2194: x0 => x0.torch,
      _2195: x0 => x0.facingMode,
      _2204: (x0,x1) => x0.key(x1),
      _2206: x0 => x0.trustedTypes,
      _2207: (x0,x1) => { x0.text = x1 },
      _2208: x0 => x0.random(),
      _2209: (x0,x1) => x0.getRandomValues(x1),
      _2210: () => globalThis.crypto,
      _2211: () => globalThis.Math,
      _2214: (x0,x1) => x0.getContext(x1),
      _2220: Function.prototype.call.bind(Number.prototype.toString),
      _2221: Function.prototype.call.bind(BigInt.prototype.toString),
      _2222: Function.prototype.call.bind(Number.prototype.toString),
      _2223: (d, digits) => d.toFixed(digits),
      _2227: () => globalThis.document,
      _2233: (x0,x1) => { x0.height = x1 },
      _2235: (x0,x1) => { x0.width = x1 },
      _2244: x0 => x0.style,
      _2247: x0 => x0.src,
      _2248: (x0,x1) => { x0.src = x1 },
      _2249: x0 => x0.naturalWidth,
      _2250: x0 => x0.naturalHeight,
      _2266: x0 => x0.status,
      _2267: (x0,x1) => { x0.responseType = x1 },
      _2269: x0 => x0.response,
      _2270: () => globalThis.google.accounts.oauth2,
      _2275: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2275(f,arguments.length,x0) }),
      _2276: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2276(f,arguments.length,x0) }),
      _2277: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12) => ({client_id: x0,scope: x1,include_granted_scopes: x2,redirect_uri: x3,callback: x4,state: x5,enable_granular_consent: x6,enable_serial_consent: x7,login_hint: x8,hd: x9,ux_mode: x10,select_account: x11,error_callback: x12}),
      _2278: x0 => x0.code,
      _2281: x0 => x0.error,
      _2284: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2284(f,arguments.length,x0) }),
      _2285: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2285(f,arguments.length,x0) }),
      _2286: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) => ({client_id: x0,callback: x1,scope: x2,include_granted_scopes: x3,prompt: x4,enable_granular_consent: x5,enable_serial_consent: x6,login_hint: x7,hd: x8,state: x9,error_callback: x10}),
      _2287: x0 => x0.requestAccessToken(),
      _2288: (x0,x1) => x0.requestAccessToken(x1),
      _2289: (x0,x1,x2,x3,x4,x5,x6) => ({scope: x0,include_granted_scopes: x1,prompt: x2,enable_granular_consent: x3,enable_serial_consent: x4,login_hint: x5,state: x6}),
      _2290: x0 => x0.access_token,
      _2291: x0 => x0.expires_in,
      _2294: x0 => x0.token_type,
      _2297: x0 => x0.error,
      _2300: x0 => x0.type,
      _2305: () => globalThis.google.accounts.id,
      _2319: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2319(f,arguments.length,x0) }),
      _2322: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16) => ({client_id: x0,auto_select: x1,callback: x2,login_uri: x3,native_callback: x4,cancel_on_tap_outside: x5,prompt_parent_id: x6,nonce: x7,context: x8,state_cookie_domain: x9,ux_mode: x10,allowed_parent_origin: x11,intermediate_iframe_close_callback: x12,itp_support: x13,login_hint: x14,hd: x15,use_fedcm_for_prompt: x16}),
      _2333: x0 => x0.error,
      _2335: x0 => x0.credential,
      _2346: x0 => { globalThis.onGoogleLibraryLoad = x0 },
      _2347: f => finalizeWrapper(f, function() { return dartInstance.exports._2347(f,arguments.length) }),
      _2396: (x0,x1) => { x0.responseType = x1 },
      _2397: x0 => x0.response,
      _2473: x0 => x0.style,
      _2672: (x0,x1) => { x0.nonce = x1 },
      _3045: x0 => x0.videoWidth,
      _3046: x0 => x0.videoHeight,
      _3076: x0 => x0.error,
      _3079: x0 => x0.srcObject,
      _3080: (x0,x1) => { x0.srcObject = x1 },
      _3104: (x0,x1) => { x0.autoplay = x1 },
      _3112: (x0,x1) => { x0.muted = x1 },
      _3127: x0 => x0.code,
      _3128: x0 => x0.message,
      _3707: (x0,x1) => { x0.src = x1 },
      _3709: (x0,x1) => { x0.type = x1 },
      _3713: (x0,x1) => { x0.async = x1 },
      _3715: (x0,x1) => { x0.defer = x1 },
      _3717: (x0,x1) => { x0.crossOrigin = x1 },
      _3719: (x0,x1) => { x0.text = x1 },
      _3752: (x0,x1) => { x0.width = x1 },
      _3754: (x0,x1) => { x0.height = x1 },
      _4173: () => globalThis.window,
      _4214: x0 => x0.document,
      _4217: x0 => x0.location,
      _4236: x0 => x0.navigator,
      _4240: x0 => x0.screen,
      _4498: x0 => x0.trustedTypes,
      _4499: x0 => x0.sessionStorage,
      _4500: x0 => x0.localStorage,
      _4515: x0 => x0.hostname,
      _4606: x0 => x0.geolocation,
      _4609: x0 => x0.mediaDevices,
      _4611: x0 => x0.permissions,
      _4626: x0 => x0.vendor,
      _4833: x0 => x0.length,
      _6737: x0 => x0.type,
      _6778: x0 => x0.signal,
      _6787: x0 => x0.length,
      _6846: () => globalThis.document,
      _6926: x0 => x0.body,
      _6928: x0 => x0.head,
      _7259: (x0,x1) => { x0.id = x1 },
      _8605: x0 => x0.value,
      _8607: x0 => x0.done,
      _8807: x0 => x0.result,
      _9299: x0 => x0.url,
      _9301: x0 => x0.status,
      _9303: x0 => x0.statusText,
      _9304: x0 => x0.headers,
      _9305: x0 => x0.body,
      _9570: x0 => x0.type,
      _9602: x0 => x0.orientation,
      _10120: x0 => x0.facingMode,
      _10195: x0 => x0.facingMode,
      _10334: x0 => x0.width,
      _10336: x0 => x0.height,
      _10419: x0 => x0.deviceId,
      _10420: x0 => x0.kind,
      _10421: x0 => x0.label,
      _11861: (x0,x1) => { x0.height = x1 },
      _12055: (x0,x1) => { x0.objectFit = x1 },
      _12185: (x0,x1) => { x0.pointerEvents = x1 },
      _12483: (x0,x1) => { x0.transform = x1 },
      _12487: (x0,x1) => { x0.transformOrigin = x1 },
      _12551: (x0,x1) => { x0.width = x1 },
      _12919: x0 => x0.name,
      _12920: x0 => x0.message,
      _13635: () => globalThis.console,
      _13661: x0 => x0.name,
      _13662: x0 => x0.message,
      _13663: x0 => x0.code,
      _13665: x0 => x0.customData,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      S: new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
