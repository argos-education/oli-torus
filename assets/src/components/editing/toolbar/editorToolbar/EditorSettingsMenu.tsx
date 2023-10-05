import React from 'react';
import { createButtonCommandDesc } from 'components/editing/elements/commands/commandFactories';
import { Toolbar } from 'components/editing/toolbar/Toolbar';
import { DropdownButton } from 'components/editing/toolbar/buttons/DropdownButton';
import { Icon } from 'components/misc/Icon';
import { classNames } from 'utils/classNames';
import styles from '../Toolbar.modules.scss';

export const editorSettingsDropdown = createButtonCommandDesc({
  icon: <Icon icon="gear" />,
  description: 'Editor Settings',
  execute: () => {},
  active: (_e) => false,
});

interface Props {
  onSwitchToMarkdown: () => void;
}
export const EditorSettingsMenu = ({ onSwitchToMarkdown }: Props) => {
  return (
    <Toolbar.Group>
      <DropdownButton description={editorSettingsDropdown} showDropdownArrow={false}>
        <button
          onClick={onSwitchToMarkdown}
          className={classNames(styles.toolbarButton, styles.descriptive)}
        >
          <Icon iconStyle="fa-brands" icon="markdown" />
          <span className={styles.description}>Switch to Markdown editor</span>
        </button>
      </DropdownButton>
    </Toolbar.Group>
  );
};