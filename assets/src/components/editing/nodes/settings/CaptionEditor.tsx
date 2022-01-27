import React from 'react';
import * as Settings from 'components/editing/nodes/settings/Settings';
import { ModelElement } from 'data/content/model/nodes/types';

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
