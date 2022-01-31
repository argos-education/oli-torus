import { createPluginFactory } from '@udecode/plate';
import { Model } from 'data/content/model/nodes/factories';

export const codeblockPlugin = createPluginFactory({
  key: 'code',
  isElement: true,
  isVoid: true,
  deserializeHtml: {
    rules: [
      {
        validNodeName: 'PRE',
      },
      {
        validNodeName: 'P',
        validStyle: {
          fontFamily: 'Consolas',
        },
      },
    ],
    getNode: (el) => {
      const languageSelectorText =
        [...el.childNodes].find((node: ChildNode) => node.nodeName === 'SELECT')?.textContent || '';

      const textContent = el.textContent?.replace(languageSelectorText, '') || '';

      return Model.code(textContent);
    },
  },
});
