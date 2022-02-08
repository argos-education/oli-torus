import React from 'react';
<<<<<<< HEAD:assets/src/components/editing/nodes/settings/CaptionEditor.tsx
import * as Settings from 'components/editing/nodes/settings/Settings';
import { ModelElement } from 'data/content/model/nodes/types';
=======
import * as Settings from 'components/editing/elements/common/settings/Settings';
import { ModelElement } from 'data/content/model/elements/types';
>>>>>>> fix-toolbar:assets/src/components/editing/nodes/common/settings/CaptionEditor.tsx

interface Props {
  onEdit: (caption: string) => void;
  model: ModelElement & { caption?: string };
}
export const CaptionEditor = (props: Props) => {
  return (
    <div contentEditable={false}>
      <Settings.Input
        value={props.model.caption}
        onChange={props.onEdit}
        model={props.model}
        placeholder="Caption"
      />
    </div>
  );
};
