import { createPluginFactory } from '@udecode/plate';
import { Model } from 'data/content/model/elements/factories';

export const codeblockPlugin = createPluginFactory({
  key: 'codeblock',
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
        Array.from(el.childNodes).find((node: ChildNode) => node.nodeName === 'SELECT')
          ?.textContent || '';

      const textContent = el.textContent?.replace(languageSelectorText, '') || '';

      return Model.code(textContent);
    },
  },
});
