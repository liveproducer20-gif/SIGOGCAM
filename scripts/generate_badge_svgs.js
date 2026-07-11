const fs = require('fs');
const path = require('path');

const output = path.join(__dirname, '..', 'mobile', 'assets', 'badges');
fs.mkdirSync(output, { recursive: true });

const palettes = [
  ['#071a32', '#ffbd12'], ['#10271d', '#9dcc2f'], ['#09263a', '#26aef2'],
  ['#28192f', '#b768c3'], ['#2b2119', '#f3a62a'], ['#2d171c', '#ef4d45'],
  ['#2b211d', '#c2783d'], ['#202a31', '#aebbc3'], ['#08232d', '#35b9c5'],
  ['#222018', '#f0b72d'],
];

const S = 'fill="none" stroke="#f4f5f6" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"';
const F = 'fill="#f4f5f6" stroke="#101820" stroke-width="3" stroke-linejoin="round"';
const A = 'fill="#ffc21c" stroke="#101820" stroke-width="2"';
const star = '<path d="M100 69l7 15 17 2-13 12 4 17-15-9-15 9 4-17-13-12 17-2z" '+A+'/>';

const icons = [
  `<path d="M72 82q28-14 56 0l-7-24q-21 10-42 0z" ${F}/><path d="M69 84q31 15 62 0" ${S}/><path d="M79 111l-12 20m54-20 12 20M83 101q17 14 34 0l-5 38H88z" ${F}/>${star.replace('M100 69','M100 112')}`,
  `<path d="M87 57l36 20-17 31-18-10-18 34" ${F}/><circle cx="97" cy="84" r="6" fill="#101820"/><path d="M65 139h48" stroke="#ffc21c" stroke-width="5"/>`,
  `<rect x="66" y="57" width="68" height="88" rx="7" ${F}/><path d="M78 51v16m15-16v16m15-16v16m15-16v16M81 86h38M81 105h38M81 124h24" ${S}/><path d="M112 124h12" stroke="#ffc21c" stroke-width="7"/>`,
  `<g transform="rotate(25 100 100)"><rect x="81" y="52" width="38" height="73" rx="17" ${F}/><path d="M83 77h34M100 125v17M82 145h36" ${S}/><path d="M86 80h28" stroke="#ffc21c" stroke-width="7"/></g>`,
  `<path d="M56 77l22-15 25 24 20-20 22 17-31 38-14-9-14 9z" ${F}/><path d="M78 91l18 17m8-14l18 17m-38-7l-7 7m17-1l-7 8m17-2l-6 7" ${S}/>` ,
  `<path d="M78 124q5-24 22-30l3-36 14 20 13 8-13 27-19 11z" ${F}/><circle cx="111" cy="83" r="4" fill="#101820"/><path d="M75 139h54M84 130h36" stroke="#9dcc2f" stroke-width="7"/>`,
  `<rect x="68" y="63" width="64" height="80" rx="4" ${F}/><path d="M87 63v-9q0-10 13-10t13 10v9M91 83h28M91 101h28M91 119h28" ${S}/><path d="M77 82l4 4 6-8m-10 23 4 4 6-8m-10 23 4 4 6-8" stroke="#ffc21c" stroke-width="5" fill="none"/>`,
  `<path d="M100 52q20 18 43 20v31q0 27-43 44-43-17-43-44V72q23-2 43-20z" ${S}/><circle cx="102" cy="99" r="17" ${S}/><path d="M113 112l16 16M102 99l11-12" ${S}/>` ,
  `<circle cx="100" cy="92" r="31" ${F}/>${star}<path d="M77 116l-7 28 20-10 10 14 10-14 20 10-7-28" ${F}/>` ,
  `<path d="M100 51l13 13 19-2 2 19 14 12-11 15 3 19-19 4-10 16-17-9-18 8-9-17-19-5 4-19-10-15 15-12 3-19 19 3z" ${F}/>${star}`,
  `<path d="M63 60h55l20 20v59H63z" ${F}/><path d="M118 60v20h20M77 96h34M77 113h22" ${S}/><circle cx="118" cy="120" r="18" ${S}/><path d="M131 133l13 13" ${S}/>` ,
  `<path d="M100 50q18 16 40 18v34q0 28-40 45-40-17-40-45V68q22-2 40-18z" ${S}/><path d="M77 116h46M82 89h36M87 89v25m13-25v25m13-25v25M78 84l22-15 22 15z" ${F}/>` ,
  `<path d="M57 70q21-13 43 0v69q-21-13-43 0zm86 0q-21-13-43 0v69q21-13 43 0z" ${F}/><path d="M124 65v40l-8-6-8 6V68" fill="#ffc21c" stroke="#101820" stroke-width="3"/>`,
  `<path d="M100 57l11 22 25 4-18 18 4 25-22-12-22 12 4-25-18-18 25-4z" ${F}/><path d="M56 131q15 15 34 6m54-6q-15 15-34 6M58 120l-9-12m93 12 9-12" ${S}/>` ,
  `<path d="M100 50q20 18 43 20v31q0 28-43 46-43-18-43-46V70q23-2 43-20z" ${S}/>${star}`,
  `<path d="M66 65h68v44q0 30-34 30t-34-30z" ${F}/>${star}<path d="M66 82H51v19q0 18 21 20m62-39h15v19q0 18-21 20M100 139v10M78 150h44" ${S}/>` ,
  `<path d="M69 84q4-24 21-25l10-15 10 15q17 1 21 25l-12 53-19-12-19 12z" ${F}/><circle cx="82" cy="78" r="5" ${A}/><circle cx="118" cy="78" r="5" ${A}/><circle cx="100" cy="57" r="5" ${A}/>` ,
  `<path d="M61 132q22-3 31-25 5-23 28-43-3 43 20 62-38-10-79 6z" ${F}/><path d="M57 141q21-8 42 0t42 0" ${S}/>` ,
  `<circle cx="100" cy="100" r="35" ${S}/><circle cx="100" cy="100" r="9" ${F}/><path d="M100 48v25m0 54v25M48 100h25m54 0h25" ${S}/>` ,
  `<circle cx="100" cy="100" r="35" ${S}/><circle cx="100" cy="100" r="9" ${A}/><path d="M100 48v25m0 54v25M48 100h25m54 0h25" ${S}/><path d="M100 72v27" stroke="#ffc21c" stroke-width="8"/>` ,
  `<path d="M94 55q-31 7-31 39t31 40q32-8 32-40T94 55z" ${S}/><path d="M82 72q-10 22 1 44m12-49q-9 27 2 53m12-47q-6 19 1 38" ${S}/><path d="M117 121l25 25" ${S}/>` ,
  `<path d="M69 61h62v17H69zm7 20h48v17H76zm8 20h32v17H84z" ${F}/><path d="M100 120v24" ${S}/>${star.replace('M100 69','M100 115')}` ,
  `<path d="M57 93q12-28 36-12 13-32 33-5 23-2 22 22-2 13-19 15H67q-19-2-10-20z" ${F}/><path d="M75 122l-7 17m34-17-7 17m34-17-7 17" stroke="#42aef5" stroke-width="7"/>` ,
  `<rect x="67" y="57" width="57" height="78" rx="4" ${F}/><path d="M80 76h31M80 94h31M80 112h20" ${S}/><path d="M116 71h17v72H76" ${S}/><path d="M106 112h9" stroke="#ffc21c" stroke-width="6"/>` ,
  `<path d="M100 50q20 18 43 20v31q0 28-43 46-43-18-43-46V70q23-2 43-20z" ${S}/>${star}`,
  `<path d="M68 59q17 10 21 29l-14 10 17 11-12 32m52-82q-17 10-21 29l14 10-17 11 12 32" ${F}/><circle cx="100" cy="111" r="22" ${S}/>` ,
  `<rect x="59" y="72" width="82" height="57" rx="6" ${F}/><path d="M82 72V60h36v12M59 94h82M100 94v35" ${S}/><circle cx="129" cy="128" r="16" ${F}/><path d="M129 104v8m0 32v8m-24-24h8m32 0h8" ${S}/>` ,
  `<path d="M84 52h32l5 20 13 15-9 9 3 32-28 17-28-17 3-32-9-9 13-15z" ${F}/>${star}` ,
  `<path d="M100 51q20 18 43 20v31q0 28-43 45-43-17-43-45V71q23-2 43-20z" ${S}/><path d="M75 89l13-9 12 9 12-9 13 9-7 34H82z" ${F}/><path d="M88 80l4-14m20 14-4-14" ${S}/>` ,
  `<path d="M67 70l33-18 33 18v48l-33 26-33-26z" ${F}/><path d="M58 69l42-23 42 23M74 121l26 20 26-20" ${S}/>${star}` ,
  `<path d="M100 57l11 22 25 4-18 18 4 25-22-12-22 12 4-25-18-18 25-4z" ${F}/><path d="M56 131q15 15 34 6m54-6q-15 15-34 6" ${S}/>` ,
  `<circle cx="100" cy="91" r="25" ${F}/>${star}<path d="M86 64l-10-14m38 14 10-14M79 119l-8 26 29-13 29 13-8-26" ${S}/>` ,
  `<path d="M100 50q20 18 43 20v31q0 28-43 46-43-18-43-46V70q23-2 43-20z" ${S}/><rect x="84" y="91" width="32" height="30" rx="3" ${F}/><path d="M90 91V80q0-10 10-10t10 10v11" ${S}/>` ,
  `<path d="M54 130l34-43 12 13 18-28 29 58z" ${F}/><path d="M88 87l7 8 5-5m18-18l7 10 5-5" ${S}/><path d="M128 49v23m0-23h20l-8 8 8 8h-20" fill="#ffc21c" stroke="#101820" stroke-width="3"/>` ,
  `<circle cx="100" cy="61" r="9" ${F}/><path d="M100 70v70M69 85h62M79 84l-17 49m59-49 17 49M75 111h50" ${S}/><circle cx="62" cy="136" r="4" ${A}/><circle cx="138" cy="136" r="4" ${A}/>` ,
  `<path d="M83 57h34l-5 25v57H88V82z" ${F}/><path d="M88 82h24M92 96h16" ${S}/>` ,
  `<path d="M59 124l25-31 17 14 35-45M117 62h19v19" ${S}/><path d="M58 70l13 13m0-13L58 83m52 38 13 13m0-13-13 13M69 120l10 10m0-10-10 10" ${S}/>` ,
  `<path d="M51 100q49-48 98 0-49 48-98 0z" ${F}/><circle cx="100" cy="100" r="20" fill="#101820"/><circle cx="106" cy="92" r="7" fill="#f4f5f6"/>` ,
  `<path d="M100 55v78M74 75h52M79 75v24h42V75M71 133h58" ${S}/><path d="M100 55l24 9-24 9" ${F}/><path d="M81 100h38v30H81z" ${F}/>` ,
  `<path d="M62 80l14-24h48l14 24-38 63z" ${F}/><path d="M62 80h76M76 56l24 87 24-87M83 80l17-24 17 24" ${S}/><path d="M126 48l4 9 10 2-7 7 2 10-9-5-9 5 2-10-7-7 10-2z" ${A}/>` ,
  `<path d="M61 137V82h78v55M79 82V65h42v17M72 137h56" ${S}/><path d="M100 52v60M81 65h38M70 94h60" ${S}/><circle cx="100" cy="55" r="6" ${F}/>` ,
  `<path d="M100 50q20 18 43 20v31q0 28-43 46-43-18-43-46V70q23-2 43-20z" ${S}/><path d="M78 116h44V91H78zM87 91V79h26v12M91 104h18" ${F}/>` ,
  `<path d="M100 50q20 18 43 20v31q0 28-43 46-43-18-43-46V70q23-2 43-20z" ${S}/><path d="M100 75v35" ${S}/><circle cx="100" cy="125" r="5" fill="#f4f5f6"/>` ,
  `<path d="M57 74q21-13 43 0v66q-21-13-43 0zm86 0q-21-13-43 0v66q21-13 43 0z" ${F}/>${star.replace('M100 69','M100 48')}` ,
  `<path d="M80 55h40l7 82-27 13-27-13z" ${F}/><circle cx="100" cy="80" r="10" ${S}/><path d="M100 90v33" ${S}/>${star.replace('M100 69','M100 111')}` ,
  `${star}<path d="M58 132q15 15 34 6m50-6q-15 15-34 6M63 121l-8-12m82 12 8-12" ${S}/><path d="M69 94l-12-8m74 8 12-8" ${S}/>` ,
  `<path d="M72 109l11-35 17 15 17-15 11 35-12 25H84z" ${F}/><circle cx="83" cy="74" r="5" ${A}/><circle cx="117" cy="74" r="5" ${A}/><circle cx="100" cy="60" r="5" ${A}/>${star.replace('M100 69','M100 96')}` ,
  `<path d="M100 50q20 18 43 20v31q0 28-43 46-43-18-43-46V70q23-2 43-20z" ${S}/>${star}<path d="M56 132q14 13 30 7m58-7q-14 13-30 7" stroke="#ffc21c" stroke-width="5" fill="none"/>`,
];

if (icons.length !== 48) throw new Error(`Expected 48 icons, got ${icons.length}`);

icons.forEach((icon, index) => {
  const number = index + 1;
  const level = number <= 40 ? Math.ceil(number / 5) : number <= 44 ? 9 : 10;
  const [bg, accent] = palettes[level - 1];
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" role="img" aria-label="Insignia ${number}">
  <defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#263442"/><stop offset="1" stop-color="${bg}"/></linearGradient></defs>
  <path d="M100 8l78 45v94l-78 45-78-45V53z" fill="${bg}" stroke="#06111c" stroke-width="6"/>
  <path d="M100 14l72 42v88l-72 42-72-42V56z" fill="url(#bg)" stroke="${accent}" stroke-width="5"/>
  <path d="M100 22l64 37v82l-64 37-64-37V59z" fill="none" stroke="#e8eef2" stroke-opacity=".45" stroke-width="2"/>
  <g>${icon}</g>
</svg>\n`;
  fs.writeFileSync(path.join(output, `badge_${String(number).padStart(2, '0')}.svg`), svg);
});

console.log(`Generated ${icons.length} badge SVGs in ${output}`);
