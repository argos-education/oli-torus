import { createMigrationsPlugin } from './migrationsPlugin';
import { codeblockPlugin } from './codeblockPlugin';
import {
  createPlugins,
  createHeadingPlugin,
  createParagraphPlugin,
  createBlockquotePlugin,
  createTablePlugin,
  createImagePlugin,
  createIndentListPlugin,
  createIndentPlugin,
  createAlignPlugin,
  createLinkPlugin,
  createBoldPlugin,
  createItalicPlugin,
  createUnderlinePlugin,
  createStrikethroughPlugin,
  createCodePlugin,
  createLineHeightPlugin,
  createSubscriptPlugin,
  createSuperscriptPlugin,
  createFontFamilyPlugin,
  createFontColorPlugin,
  createFontSizePlugin,
  createFontWeightPlugin,
  createNodeIdPlugin,
  createAutoformatPlugin,
  createResetNodePlugin,
  createSoftBreakPlugin,
  createExitBreakPlugin,
  createSelectOnBackspacePlugin,
  createTrailingBlockPlugin,
  createDeserializeMdPlugin,
  createDeserializeAstPlugin,
  createDeserializeCsvPlugin,
  createDeserializeDocxPlugin,
  createDeserializeHtmlPlugin,
  createMediaEmbedPlugin,
  createHorizontalRulePlugin,
  createPluginFactory,
  getText,
} from '@udecode/plate';
import { pluginConfig as config } from './pluginConfig';
import { pluginComponents as components } from './components';
import { Element } from 'slate';

export const plugins = createPlugins(
  [
    // Blocks
    createHeadingPlugin(),
    createParagraphPlugin(),
    createBlockquotePlugin(),
    createTablePlugin(),
    createImagePlugin(),
    createSelectOnBackspacePlugin(config.selectOnBackspace),
    createLineHeightPlugin(config.lineHeight),
    codeblockPlugin(),
    createImagePlugin(),
    createHorizontalRulePlugin(),
    createIndentListPlugin(),
    createIndentPlugin(config.indent),
    createAlignPlugin(config.align),

    // Inlines
    createLinkPlugin(),

    // Marks
    createBoldPlugin(),
    createItalicPlugin(),
    createUnderlinePlugin(),
    createStrikethroughPlugin(),
    createCodePlugin(),
    createSubscriptPlugin(),
    createSuperscriptPlugin(),

    // Paragraph / Heading
    createFontFamilyPlugin(),
    createFontColorPlugin(),
    createFontSizePlugin(),
    createFontWeightPlugin(),
    createMediaEmbedPlugin(),

    // Normalizers
    // createNormalizeTypesPlugin({
    //   rules: [{ path: getNodes(editor), strictType: ELEMENT_H1 }],
    // } as any),

    // Other
    createAutoformatPlugin(config.autoformat),
    // enter / backspace to reset node to default
    createResetNodePlugin(config.resetNode),
    // shift-enter to newline
    createSoftBreakPlugin(config.softBreak),
    // hotkeys to exit current block - e.g. for codeblocks
    createExitBreakPlugin(config.exitBreak),
    createMigrationsPlugin(),
    createNodeIdPlugin(),

    // deserializers
    createDeserializeMdPlugin(),
    createDeserializeAstPlugin(),
    createDeserializeCsvPlugin(),
    createDeserializeDocxPlugin(),
    createDeserializeHtmlPlugin(),

    createTrailingBlockPlugin(config.trailingBlock),
  ],
  {
    components,
  },
);
