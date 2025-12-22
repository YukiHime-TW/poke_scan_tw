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
      _1333: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1375: x0 => x0.toArray(),
      _1376: x0 => x0.toUint8Array(),
      _1377: x0 => ({serverTimestamps: x0}),
      _1378: x0 => ({source: x0}),
      _1381: x0 => new firebase_firestore.FieldPath(x0),
      _1382: (x0,x1) => new firebase_firestore.FieldPath(x0,x1),
      _1383: (x0,x1,x2) => new firebase_firestore.FieldPath(x0,x1,x2),
      _1384: (x0,x1,x2,x3) => new firebase_firestore.FieldPath(x0,x1,x2,x3),
      _1385: (x0,x1,x2,x3,x4) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4),
      _1386: (x0,x1,x2,x3,x4,x5) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5),
      _1387: (x0,x1,x2,x3,x4,x5,x6) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6),
      _1388: (x0,x1,x2,x3,x4,x5,x6,x7) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7),
      _1389: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8),
      _1390: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9),
      _1391: () => globalThis.firebase_firestore.documentId(),
      _1392: (x0,x1) => new firebase_firestore.GeoPoint(x0,x1),
      _1393: x0 => globalThis.firebase_firestore.vector(x0),
      _1394: x0 => globalThis.firebase_firestore.Bytes.fromUint8Array(x0),
      _1396: (x0,x1) => globalThis.firebase_firestore.collection(x0,x1),
      _1398: (x0,x1) => globalThis.firebase_firestore.doc(x0,x1),
      _1403: x0 => x0.call(),
      _1433: x0 => globalThis.firebase_firestore.getDoc(x0),
      _1434: x0 => globalThis.firebase_firestore.getDocFromServer(x0),
      _1435: x0 => globalThis.firebase_firestore.getDocFromCache(x0),
      _1442: (x0,x1) => globalThis.firebase_firestore.setDoc(x0,x1),
      _1459: (x0,x1) => x0.data(x1),
      _1472: () => globalThis.firebase_firestore.serverTimestamp(),
      _1480: (x0,x1) => globalThis.firebase_firestore.getFirestore(x0,x1),
      _1482: x0 => globalThis.firebase_firestore.Timestamp.fromMillis(x0),
      _1483: f => finalizeWrapper(f, function() { return dartInstance.exports._1483(f,arguments.length) }),
      _1499: () => globalThis.firebase_firestore.updateDoc,
      _1506: x0 => x0.path,
      _1509: () => globalThis.firebase_firestore.GeoPoint,
      _1510: x0 => x0.latitude,
      _1511: x0 => x0.longitude,
      _1513: () => globalThis.firebase_firestore.VectorValue,
      _1514: () => globalThis.firebase_firestore.Bytes,
      _1525: () => globalThis.firebase_firestore.DocumentReference,
      _1529: x0 => x0.path,
      _1538: x0 => x0.metadata,
      _1539: x0 => x0.ref,
      _1550: () => globalThis.firebase_firestore.Timestamp,
      _1551: x0 => x0.seconds,
      _1552: x0 => x0.nanoseconds,
      _1589: x0 => x0.hasPendingWrites,
      _1591: x0 => x0.fromCache,
      _1598: x0 => x0.source,
      _1615: (x0,x1) => x0.createElement(x1),
      _1621: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1631: (x0,x1) => x0.item(x1),
      _1632: (x0,x1) => x0.querySelector(x1),
      _1633: (x0,x1) => x0.getAttribute(x1),
      _1634: (x0,x1) => x0.createElement(x1),
      _1636: (x0,x1) => x0.initialize(x1),
      _1637: (x0,x1) => x0.initTokenClient(x1),
      _1638: (x0,x1) => x0.initCodeClient(x1),
      _1640: (x0,x1) => x0.warn(x1),
      _1641: x0 => x0.disableAutoSelect(),
      _1642: x0 => x0.decode(),
      _1643: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1644: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1645: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1645(f,arguments.length,x0) }),
      _1646: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1646(f,arguments.length,x0) }),
      _1647: x0 => x0.send(),
      _1648: () => new XMLHttpRequest(),
      _1669: x0 => x0.toJSON(),
      _1670: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1670(f,arguments.length,x0) }),
      _1671: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1671(f,arguments.length,x0) }),
      _1672: (x0,x1,x2) => x0.onAuthStateChanged(x1,x2),
      _1673: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1673(f,arguments.length,x0) }),
      _1674: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1674(f,arguments.length,x0) }),
      _1675: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1675(f,arguments.length,x0) }),
      _1676: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1676(f,arguments.length,x0) }),
      _1677: (x0,x1,x2) => x0.onIdTokenChanged(x1,x2),
      _1688: (x0,x1) => globalThis.firebase_auth.signInWithCredential(x0,x1),
      _1696: x0 => x0.signOut(),
      _1697: (x0,x1) => globalThis.firebase_auth.connectAuthEmulator(x0,x1),
      _1715: (x0,x1) => globalThis.firebase_auth.GoogleAuthProvider.credential(x0,x1),
      _1716: x0 => new firebase_auth.OAuthProvider(x0),
      _1719: (x0,x1) => x0.credential(x1),
      _1720: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromResult(x0),
      _1735: x0 => globalThis.firebase_auth.getAdditionalUserInfo(x0),
      _1736: (x0,x1,x2) => ({errorMap: x0,persistence: x1,popupRedirectResolver: x2}),
      _1737: (x0,x1) => globalThis.firebase_auth.initializeAuth(x0,x1),
      _1738: (x0,x1,x2) => ({accessToken: x0,idToken: x1,rawNonce: x2}),
      _1743: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromError(x0),
      _1758: () => globalThis.firebase_auth.debugErrorMap,
      _1761: () => globalThis.firebase_auth.browserSessionPersistence,
      _1763: () => globalThis.firebase_auth.browserLocalPersistence,
      _1765: () => globalThis.firebase_auth.indexedDBLocalPersistence,
      _1768: x0 => globalThis.firebase_auth.multiFactor(x0),
      _1769: (x0,x1) => globalThis.firebase_auth.getMultiFactorResolver(x0,x1),
      _1771: x0 => x0.currentUser,
      _1785: x0 => x0.displayName,
      _1786: x0 => x0.email,
      _1787: x0 => x0.phoneNumber,
      _1788: x0 => x0.photoURL,
      _1789: x0 => x0.providerId,
      _1790: x0 => x0.uid,
      _1791: x0 => x0.emailVerified,
      _1792: x0 => x0.isAnonymous,
      _1793: x0 => x0.providerData,
      _1794: x0 => x0.refreshToken,
      _1795: x0 => x0.tenantId,
      _1796: x0 => x0.metadata,
      _1798: x0 => x0.providerId,
      _1799: x0 => x0.signInMethod,
      _1800: x0 => x0.accessToken,
      _1801: x0 => x0.idToken,
      _1802: x0 => x0.secret,
      _1813: x0 => x0.creationTime,
      _1814: x0 => x0.lastSignInTime,
      _1819: x0 => x0.code,
      _1821: x0 => x0.message,
      _1833: x0 => x0.email,
      _1834: x0 => x0.phoneNumber,
      _1835: x0 => x0.tenantId,
      _1858: x0 => x0.user,
      _1861: x0 => x0.providerId,
      _1862: x0 => x0.profile,
      _1863: x0 => x0.username,
      _1864: x0 => x0.isNewUser,
      _1867: () => globalThis.firebase_auth.browserPopupRedirectResolver,
      _1872: x0 => x0.displayName,
      _1873: x0 => x0.enrollmentTime,
      _1874: x0 => x0.factorId,
      _1875: x0 => x0.uid,
      _1877: x0 => x0.hints,
      _1878: x0 => x0.session,
      _1880: x0 => x0.phoneNumber,
      _1892: (x0,x1) => x0.getItem(x1),
      _1898: (x0,x1) => x0.appendChild(x1),
      _1903: (x0,x1,x2) => x0.setItem(x1,x2),
      _1916: (x0,x1,x2,x3,x4,x5,x6,x7) => ({apiKey: x0,authDomain: x1,databaseURL: x2,projectId: x3,storageBucket: x4,messagingSenderId: x5,measurementId: x6,appId: x7}),
      _1917: (x0,x1) => globalThis.firebase_core.initializeApp(x0,x1),
      _1918: x0 => globalThis.firebase_core.getApp(x0),
      _1919: () => globalThis.firebase_core.getApp(),
      _1921: () => globalThis.firebase_core.SDK_VERSION,
      _1927: x0 => x0.apiKey,
      _1929: x0 => x0.authDomain,
      _1931: x0 => x0.databaseURL,
      _1933: x0 => x0.projectId,
      _1935: x0 => x0.storageBucket,
      _1937: x0 => x0.messagingSenderId,
      _1939: x0 => x0.measurementId,
      _1941: x0 => x0.appId,
      _1943: x0 => x0.name,
      _1944: x0 => x0.options,
      _1945: (x0,x1) => x0.debug(x1),
      _1946: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1946(f,arguments.length,x0) }),
      _1947: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1947(f,arguments.length,x0,x1) }),
      _1948: (x0,x1) => ({createScript: x0,createScriptURL: x1}),
      _1949: (x0,x1,x2) => x0.createPolicy(x1,x2),
      _1950: (x0,x1) => x0.createScriptURL(x1),
      _1951: (x0,x1,x2) => x0.createScript(x1,x2),
      _1952: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1952(f,arguments.length,x0) }),
      _1954: Date.now,
      _1956: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1957: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1958: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _1959: () => typeof dartUseDateNowForTicks !== "undefined",
      _1960: () => 1000 * performance.now(),
      _1961: () => Date.now(),
      _1962: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _1963: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _1964: () => new WeakMap(),
      _1965: (map, o) => map.get(o),
      _1966: (map, o, v) => map.set(o, v),
      _1967: x0 => new WeakRef(x0),
      _1968: x0 => x0.deref(),
      _1975: () => globalThis.WeakRef,
      _1978: s => JSON.stringify(s),
      _1979: s => printToConsole(s),
      _1980: (o, p, r) => o.replaceAll(p, () => r),
      _1981: (o, p, r) => o.replace(p, () => r),
      _1982: Function.prototype.call.bind(String.prototype.toLowerCase),
      _1983: s => s.toUpperCase(),
      _1984: s => s.trim(),
      _1985: s => s.trimLeft(),
      _1986: s => s.trimRight(),
      _1987: (string, times) => string.repeat(times),
      _1988: Function.prototype.call.bind(String.prototype.indexOf),
      _1989: (s, p, i) => s.lastIndexOf(p, i),
      _1990: (string, token) => string.split(token),
      _1991: Object.is,
      _1992: o => o instanceof Array,
      _1993: (a, i) => a.push(i),
      _1997: a => a.pop(),
      _1998: (a, i) => a.splice(i, 1),
      _1999: (a, s) => a.join(s),
      _2000: (a, s, e) => a.slice(s, e),
      _2002: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _2003: a => a.length,
      _2005: (a, i) => a[i],
      _2006: (a, i, v) => a[i] = v,
      _2008: o => {
        if (o instanceof ArrayBuffer) return 0;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 1;
        }
        return 2;
      },
      _2009: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _2011: o => o instanceof Uint8Array,
      _2012: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _2013: o => o instanceof Int8Array,
      _2014: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _2015: o => o instanceof Uint8ClampedArray,
      _2016: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _2017: o => o instanceof Uint16Array,
      _2018: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _2019: o => o instanceof Int16Array,
      _2020: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _2021: o => o instanceof Uint32Array,
      _2022: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _2023: o => o instanceof Int32Array,
      _2024: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _2026: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _2027: o => o instanceof Float32Array,
      _2028: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _2029: o => o instanceof Float64Array,
      _2030: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _2031: (t, s) => t.set(s),
      _2033: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _2035: o => o.buffer,
      _2036: o => o.byteOffset,
      _2037: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _2038: (b, o) => new DataView(b, o),
      _2039: (b, o, l) => new DataView(b, o, l),
      _2040: Function.prototype.call.bind(DataView.prototype.getUint8),
      _2041: Function.prototype.call.bind(DataView.prototype.setUint8),
      _2042: Function.prototype.call.bind(DataView.prototype.getInt8),
      _2043: Function.prototype.call.bind(DataView.prototype.setInt8),
      _2044: Function.prototype.call.bind(DataView.prototype.getUint16),
      _2045: Function.prototype.call.bind(DataView.prototype.setUint16),
      _2046: Function.prototype.call.bind(DataView.prototype.getInt16),
      _2047: Function.prototype.call.bind(DataView.prototype.setInt16),
      _2048: Function.prototype.call.bind(DataView.prototype.getUint32),
      _2049: Function.prototype.call.bind(DataView.prototype.setUint32),
      _2050: Function.prototype.call.bind(DataView.prototype.getInt32),
      _2051: Function.prototype.call.bind(DataView.prototype.setInt32),
      _2054: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _2055: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _2056: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _2057: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _2058: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _2059: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _2072: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _2073: (handle) => clearTimeout(handle),
      _2074: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _2075: (handle) => clearInterval(handle),
      _2076: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _2077: () => Date.now(),
      _2078: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _2079: (x0,x1) => x0.exec(x1),
      _2080: (x0,x1) => x0.test(x1),
      _2081: x0 => x0.pop(),
      _2083: o => o === undefined,
      _2085: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _2087: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _2088: o => o instanceof RegExp,
      _2089: (l, r) => l === r,
      _2090: o => o,
      _2091: o => o,
      _2092: o => o,
      _2093: b => !!b,
      _2094: o => o.length,
      _2096: (o, i) => o[i],
      _2097: f => f.dartFunction,
      _2098: () => ({}),
      _2099: () => [],
      _2101: () => globalThis,
      _2102: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _2103: (o, p) => p in o,
      _2104: (o, p) => o[p],
      _2105: (o, p, v) => o[p] = v,
      _2106: (o, m, a) => o[m].apply(o, a),
      _2108: o => String(o),
      _2109: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _2110: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2110(f,arguments.length,x0) }),
      _2111: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._2111(f,arguments.length,x0,x1) }),
      _2112: o => {
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
      _2113: o => [o],
      _2114: (o0, o1) => [o0, o1],
      _2115: (o0, o1, o2) => [o0, o1, o2],
      _2116: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _2117: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2118: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2121: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2122: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2123: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2124: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2125: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2126: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2127: x0 => new ArrayBuffer(x0),
      _2128: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _2130: x0 => x0.index,
      _2131: x0 => x0.groups,
      _2132: x0 => x0.flags,
      _2133: x0 => x0.multiline,
      _2134: x0 => x0.ignoreCase,
      _2135: x0 => x0.unicode,
      _2136: x0 => x0.dotAll,
      _2137: (x0,x1) => { x0.lastIndex = x1 },
      _2138: (o, p) => p in o,
      _2139: (o, p) => o[p],
      _2140: (o, p, v) => o[p] = v,
      _2141: (o, p) => delete o[p],
      _2165: () => new AbortController(),
      _2166: x0 => x0.abort(),
      _2167: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _2168: (x0,x1) => globalThis.fetch(x0,x1),
      _2169: (x0,x1) => x0.get(x1),
      _2170: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._2170(f,arguments.length,x0,x1,x2) }),
      _2171: (x0,x1) => x0.forEach(x1),
      _2172: x0 => x0.getReader(),
      _2173: x0 => x0.cancel(),
      _2174: x0 => x0.read(),
      _2175: x0 => x0.trustedTypes,
      _2176: (x0,x1) => { x0.src = x1 },
      _2177: (x0,x1) => x0.createScriptURL(x1),
      _2178: x0 => x0.nonce,
      _2179: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2179(f,arguments.length,x0) }),
      _2180: x0 => ({createScriptURL: x0}),
      _2181: (x0,x1) => x0.querySelectorAll(x1),
      _2196: (x0,x1) => x0.key(x1),
      _2197: x0 => x0.trustedTypes,
      _2198: (x0,x1) => { x0.text = x1 },
      _2199: x0 => x0.random(),
      _2202: () => globalThis.Math,
      _2211: Function.prototype.call.bind(Number.prototype.toString),
      _2212: Function.prototype.call.bind(BigInt.prototype.toString),
      _2213: Function.prototype.call.bind(Number.prototype.toString),
      _2214: (d, digits) => d.toFixed(digits),
      _2218: () => globalThis.document,
      _2224: (x0,x1) => { x0.height = x1 },
      _2226: (x0,x1) => { x0.width = x1 },
      _2235: x0 => x0.style,
      _2238: x0 => x0.src,
      _2239: (x0,x1) => { x0.src = x1 },
      _2240: x0 => x0.naturalWidth,
      _2241: x0 => x0.naturalHeight,
      _2257: x0 => x0.status,
      _2258: (x0,x1) => { x0.responseType = x1 },
      _2260: x0 => x0.response,
      _2261: () => globalThis.google.accounts.oauth2,
      _2266: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2266(f,arguments.length,x0) }),
      _2267: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2267(f,arguments.length,x0) }),
      _2268: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12) => ({client_id: x0,scope: x1,include_granted_scopes: x2,redirect_uri: x3,callback: x4,state: x5,enable_granular_consent: x6,enable_serial_consent: x7,login_hint: x8,hd: x9,ux_mode: x10,select_account: x11,error_callback: x12}),
      _2269: x0 => x0.code,
      _2272: x0 => x0.error,
      _2275: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2275(f,arguments.length,x0) }),
      _2276: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2276(f,arguments.length,x0) }),
      _2277: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) => ({client_id: x0,callback: x1,scope: x2,include_granted_scopes: x3,prompt: x4,enable_granular_consent: x5,enable_serial_consent: x6,login_hint: x7,hd: x8,state: x9,error_callback: x10}),
      _2278: x0 => x0.requestAccessToken(),
      _2279: (x0,x1) => x0.requestAccessToken(x1),
      _2280: (x0,x1,x2,x3,x4,x5,x6) => ({scope: x0,include_granted_scopes: x1,prompt: x2,enable_granular_consent: x3,enable_serial_consent: x4,login_hint: x5,state: x6}),
      _2281: x0 => x0.access_token,
      _2282: x0 => x0.expires_in,
      _2285: x0 => x0.token_type,
      _2288: x0 => x0.error,
      _2291: x0 => x0.type,
      _2296: () => globalThis.google.accounts.id,
      _2310: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._2310(f,arguments.length,x0) }),
      _2313: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16) => ({client_id: x0,auto_select: x1,callback: x2,login_uri: x3,native_callback: x4,cancel_on_tap_outside: x5,prompt_parent_id: x6,nonce: x7,context: x8,state_cookie_domain: x9,ux_mode: x10,allowed_parent_origin: x11,intermediate_iframe_close_callback: x12,itp_support: x13,login_hint: x14,hd: x15,use_fedcm_for_prompt: x16}),
      _2324: x0 => x0.error,
      _2326: x0 => x0.credential,
      _2337: x0 => { globalThis.onGoogleLibraryLoad = x0 },
      _2338: f => finalizeWrapper(f, function() { return dartInstance.exports._2338(f,arguments.length) }),
      _2663: (x0,x1) => { x0.nonce = x1 },
      _3698: (x0,x1) => { x0.src = x1 },
      _3700: (x0,x1) => { x0.type = x1 },
      _3704: (x0,x1) => { x0.async = x1 },
      _3706: (x0,x1) => { x0.defer = x1 },
      _3708: (x0,x1) => { x0.crossOrigin = x1 },
      _3710: (x0,x1) => { x0.text = x1 },
      _4165: () => globalThis.window,
      _4206: x0 => x0.document,
      _4209: x0 => x0.location,
      _4228: x0 => x0.navigator,
      _4490: x0 => x0.trustedTypes,
      _4491: x0 => x0.sessionStorage,
      _4492: x0 => x0.localStorage,
      _4507: x0 => x0.hostname,
      _4598: x0 => x0.geolocation,
      _4601: x0 => x0.mediaDevices,
      _4603: x0 => x0.permissions,
      _4825: x0 => x0.length,
      _6770: x0 => x0.signal,
      _6779: x0 => x0.length,
      _6838: () => globalThis.document,
      _6920: x0 => x0.head,
      _7252: (x0,x1) => { x0.id = x1 },
      _8598: x0 => x0.value,
      _8600: x0 => x0.done,
      _9293: x0 => x0.url,
      _9295: x0 => x0.status,
      _9297: x0 => x0.statusText,
      _9298: x0 => x0.headers,
      _9299: x0 => x0.body,
      _12913: x0 => x0.name,
      _13630: () => globalThis.console,
      _13656: x0 => x0.name,
      _13657: x0 => x0.message,
      _13658: x0 => x0.code,
      _13660: x0 => x0.customData,

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
