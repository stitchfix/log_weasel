import { ulid } from 'ulid';
import { constantCase } from 'constant-case';

// Keep the type signature of this function in sync with the types exposed in
// index.d.ts
const generateId = (key) => {
  if (typeof key === 'undefined') {
    throw new TypeError('LogWeasel generateID requires a key argument');
  }

  return `${ulid()}-${constantCase(key)}-JS`;
};

export default generateId;
