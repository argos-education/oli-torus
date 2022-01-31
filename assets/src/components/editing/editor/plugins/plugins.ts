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
  ELEMENT_IMAGE,
  setNodes,
} from '@udecode/plate';
import { pluginConfig as config } from './pluginConfig';
import { pluginComponents as components } from './components';
import { Editor, Element } from 'slate';

export const plugins = createPlugins(
  [
    // Blocks
    createHeadingPlugin(),
    createParagraphPlugin(),
    createBlockquotePlugin(),
    createTablePlugin(),
    createImagePlugin({
      //       withOverrides: (editor, _plugin) => {
      // //         const normalizeNode = editor.normalizeNode;
      // //         console.log('normalizing');
      // //         editor.normalizeNode = (entry) => {
      // //           const [node, path] = entry;
      // //           /*
      // // export interface Image extends SlateElement<VoidChildren> {
      // //   type: 'img';
      // //   src?: string;
      // //   height?: number;
      // //   width?: number;
      // //   alt?: string;
      // //   caption?: string;
      // //   // Legacy, unused;
      // //   display?: string;
      // // }
      // //           */
      // //           if (Element.isElement(node) && node.type === 'img') {
      // //             console.log('image', node);
      // //           }
      // //           return normalizeNode(entry);
      // //         };
      // //         return editor;
      //       },
    }),
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
