import { EventEmitter } from 'events';
import jsonc from 'comment-json';

/**
 * Custom JSON parser for localizing keys matching format: /%.+%/
 */
export const CustomJSONLexer = class extends EventEmitter {
  extract(content, filename) {
    let keys = [];
    console.log(1)
    try {
      jsonc.parse(
        content,
        (key, value) => {
          if (typeof value === 'string') {
            const match = value.match(/^%(.+)%$/);
            if (match && match[1]) {
              keys.push({ key: match[1] });
            }
          }
          return value;
        },
        true,
      );
    } catch (e) {
      console.error('Failed to parse as JSON.', filename, e);
      keys = [];
    }
    return keys;
  }
};
