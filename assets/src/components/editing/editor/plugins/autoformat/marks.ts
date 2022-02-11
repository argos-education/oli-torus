import {
  AutoformatRule,
  MARK_BOLD,
  MARK_ITALIC,
  MARK_UNDERLINE,
  MARK_STRIKETHROUGH,
  MARK_SUPERSCRIPT,
  MARK_SUBSCRIPT,
  MARK_HIGHLIGHT,
  MARK_CODE,
} from '@udecode/plate';

export const autoformatMarks: AutoformatRule[] = [
  {
    mode: 'mark',
    type: [MARK_BOLD, MARK_ITALIC],
    match: '***',
  },
  {
    mode: 'mark',
    type: [MARK_UNDERLINE, MARK_ITALIC],
    match: '__*',
  },
  {
    mode: 'mark',
    type: [MARK_UNDERLINE, MARK_BOLD],
    match: '__**',
  },
  {
    mode: 'mark',
    type: [MARK_UNDERLINE, MARK_BOLD, MARK_ITALIC],
    match: '___***',
  },
  {
    mode: 'mark',
    type: MARK_BOLD,
    match: '**',
  },
  {
    mode: 'mark',
    type: MARK_UNDERLINE,
    match: '__',
  },
  {
    mode: 'mark',
    type: MARK_ITALIC,
    match: '*',
  },
  {
    mode: 'mark',
    type: MARK_ITALIC,
    match: '_',
  },
  {
    mode: 'mark',
    type: MARK_STRIKETHROUGH,
    match: '~~',
  },
  {
    mode: 'mark',
    type: MARK_SUPERSCRIPT,
    match: '^',
  },
  {
    mode: 'mark',
    type: MARK_SUBSCRIPT,
    match: '~',
  },
  {
    mode: 'mark',
    type: MARK_HIGHLIGHT,
    match: '==',
  },
  {
    mode: 'mark',
    type: MARK_HIGHLIGHT,
    match: '≡',
  },
  {
    mode: 'mark',
    type: MARK_CODE,
    match: '`',
  },
];
