import React from 'react';
import { useFocused, useSelected, useSlate } from 'slate-react';
<<<<<<< HEAD:assets/src/components/editing/nodes/table/ThEditor.tsx
import * as ContentModel from 'data/content/model/nodes/types';
import { EditorProps } from 'components/editing/nodes/interfaces';
import { DropdownMenu } from './DropdownMenu';
=======
import * as ContentModel from 'data/content/model/elements/types';
import { EditorProps } from 'components/editing/elements/interfaces';
import { DropdownMenu } from './TableDropdownMenu';
>>>>>>> fix-toolbar:assets/src/components/editing/nodes/table/ThElement.tsx

export const ThEditor = (props: EditorProps<ContentModel.TableHeader>) => {
  const editor = useSlate();
  const selected = useSelected();
  const focused = useFocused();

  const maybeMenu =
    selected && focused ? <DropdownMenu editor={editor} model={props.model} /> : null;

  return (
    <th {...props.attributes}>
      {maybeMenu}
      {props.children}
    </th>
  );
};
