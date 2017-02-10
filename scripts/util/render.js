const dots = require('./dots');

const render = {};

render.nothing = sh => Object.assign({
  exposeAs: null,
}, sh);

render.enum = sh => Object.assign({
  exposeAs: `${sh.type}(..)`,
  typeDef: dots.defineUnionType(sh),
  decoderDef: dots.defineUnionDecoder(sh),
}, sh);

render.enumDoc = dots.defineUnionDoc;

const memberType = ({ key, value }) =>
  `${key} : ${value.type}`;

const memberDecoder = ({ required, key, value }) =>
  [
    `JDP.${required ? 'required' : 'optional'}`,
    `"${key}"`,
    `${value.decoder}`,
  ].join(' ');

render.structure = sh => Object.assign({
  exposeAs: sh.category !== 'request' ? sh.type : null,
  typeDef: dots.defineRecordType(Object.assign({ memberType }, sh)),
  decoderDef: dots.defineRecordDecoder(Object.assign({ memberDecoder }, sh)),
}, sh);

module.exports = render;