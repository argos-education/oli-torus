import {
  autoformatSmartQuotes,
  autoformatPunctuation,
  autoformatLegal,
  autoformatLegalHtml,
  autoformatArrow,
  autoformatMath,
} from '@udecode/plate';
import { autoformatBlocks } from 'components/editing/editor/plugins/autoformat/blocks';
import { autoformatLists } from 'components/editing/editor/plugins/autoformat/lists';
import { autoformatMarks } from 'components/editing/editor/plugins/autoformat/marks';

export const autoformatRules = [
  ...autoformatBlocks,
  ...autoformatLists,
  ...autoformatMarks,
  ...autoformatSmartQuotes,
  ...autoformatPunctuation,
  ...autoformatLegal,
  ...autoformatLegalHtml,
  ...autoformatArrow,
  ...autoformatMath,
];
