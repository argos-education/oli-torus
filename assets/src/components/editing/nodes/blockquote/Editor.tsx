import React from 'react';
import * as ContentModel from 'data/content/model/nodes/types';
import { EditorProps } from 'components/editing/nodes/interfaces';
export interface Props extends EditorProps<ContentModel.Blockquote> {}
export const BlockQuoteEditor = (props: Props) => {
  return <blockquote {...props.attributes}>{props.children}</blockquote>;
};
