import React from 'react';
import { useFocused, useSelected, useSlate } from 'slate-react';
<<<<<<< HEAD:assets/src/components/editing/nodes/table/TdEditor.tsx
import * as ContentModel from 'data/content/model/nodes/types';
import { EditorProps } from 'components/editing/nodes/interfaces';
import { DropdownMenu } from './DropdownMenu';
=======
import * as ContentModel from 'data/content/model/elements/types';
import { EditorProps } from 'components/editing/elements/interfaces';
import { DropdownMenu } from './TableDropdownMenu';
>>>>>>> fix-toolbar:assets/src/components/editing/nodes/table/TdElement.tsx

export const TdEditor = (props: EditorProps<ContentModel.TableData>) => {
  const editor = useSlate();
  const selected = useSelected();
  const focused = useFocused();

  const maybeMenu =
    selected && focused ? <DropdownMenu editor={editor} model={props.model} /> : null;

  return (
    <td {...props.attributes}>
      {maybeMenu}
      {props.children}
    </td>
  );
};
