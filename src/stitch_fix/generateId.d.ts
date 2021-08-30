// Although this is not a TS package, types are exported to support TS
// applications. Please keep the types here in sync with the type signature of
// the export in generateId.js
declare const generateId: (key: string) => string;

export default generateId;
