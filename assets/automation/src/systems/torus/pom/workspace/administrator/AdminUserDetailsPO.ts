import { Page, Locator } from '@playwright/test';
import { FileManager } from '@core/FileManager';
import { Utils } from '@core/Utils';

export class AdminUserDetailsPO {
  private utils: Utils;
  private editButton: Locator;
  private checkBox: Locator;
  private saveButton: Locator;

  constructor(private page: Page) {
    this.utils = new Utils(this.page);
    this.editButton = this.page.getByRole('button', { name: 'Edit' });
    this.checkBox = this.page.getByRole('checkbox', {
      name: 'Can Create Sections',
    });
    this.saveButton = this.page.getByRole('button', { name: 'Save' });
  }

  async goToUserEditPage(userId: string) {
    const baseUrl = FileManager.getValueEnv('BASE_URL');
    await this.page.goto(`${baseUrl}/admin/users/${userId}`);
  }

  async clickEditButton() {
    await this.utils.forceClick(this.editButton, this.saveButton);
  }

  async checkCreateSections() {
    await this.checkBox.check();
  }

  async clickSaveButton() {
    await this.utils.forceClick(this.saveButton, this.editButton);
  }
}
