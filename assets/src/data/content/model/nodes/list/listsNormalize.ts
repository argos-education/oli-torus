<<<<<<< HEAD:assets/src/data/content/model/nodes/list/listsNormalize.ts
import { Transforms, Node, Path, Editor, Element, Text } from 'slate';
import { Model } from 'data/content/model/nodes/factories';
import { ModelElement } from 'data/content/model/nodes/types';
=======
import { Transforms, Path, Editor, Element, Text } from 'slate';
import { Model } from 'data/content/model/elements/factories';
import { ModelElement } from 'data/content/model/elements/types';
>>>>>>> fix-toolbar:assets/src/components/editing/editor/normalizers/lists.ts
import { FormattedText } from 'data/content/model/text';
import { schema } from 'data/content/model/schema';

export const normalize = (editor: Editor, node: ModelElement | FormattedText, path: Path) => {
  const [parent] = Editor.parent(editor, path);

  if (Element.isElement(parent)) {
    const config = schema[parent.type];
    if (['ol', 'ul'].includes(parent.type)) {
      if (Text.isText(node)) {
        Transforms.wrapNodes(editor, Model.li(), { at: path });
        return;
      }
      if (Element.isElement(node) && !config.validChildren[node.type]) {
        Transforms.setNodes(editor, { type: 'li' }, { at: path });
        return;
      }
    }
  }
};
