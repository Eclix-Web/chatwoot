<script>
// Eclixtech fork (eclix/patches/0002): SMTP for website inboxes. Reuses the
// Email inbox SmtpSettings logic, adds a From address and the toggle layout
// used by the other website inbox settings.
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import InputRadioGroup from './components/InputRadioGroup.vue';
import SingleSelectDropdown from './components/SingleSelectDropdown.vue';
import SmtpSettings from './SmtpSettings.vue';

export default {
  components: {
    SettingsToggleSection,
    NextButton,
    InputRadioGroup,
    SingleSelectDropdown,
  },
  extends: SmtpSettings,
  // setup() is not inherited through extends in Vue 3.
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return { fromEmail: '', isSettingDefaults: false };
  },
  validations: {
    fromEmail: { required, email },
    address: { required },
    port: { required, minLength: minLength(2) },
    login: { required },
    password: { required },
    domain: { required },
  },
  watch: {
    isSMTPEnabled(enabled) {
      // Turning it off saves straight away, like the other toggles here;
      // turning it on reveals the form, which is saved with its button.
      if (!enabled && !this.isSettingDefaults && this.inbox.smtp_enabled) {
        this.updateInbox();
      }
    },
  },
  methods: {
    setDefaults() {
      this.isSettingDefaults = true;
      SmtpSettings.methods.setDefaults.call(this);
      this.fromEmail = this.inbox.smtp_from_email;
      this.$nextTick(() => {
        this.isSettingDefaults = false;
      });
    },
    async updateInbox() {
      try {
        await this.$store.dispatch('inboxes/updateInboxSMTP', {
          id: this.inbox.id,
          channel: {
            smtp_enabled: this.isSMTPEnabled,
            smtp_from_email: this.fromEmail,
            smtp_address: this.address,
            smtp_port: this.port,
            smtp_login: this.login,
            smtp_password: this.password,
            smtp_domain: this.domain,
            smtp_enable_ssl_tls: this.ssl,
            smtp_enable_starttls_auto: this.starttls,
            smtp_openssl_verify_mode: this.openSSLVerifyMode,
            smtp_authentication: this.authMechanism,
          },
        });
        useAlert(this.$t('INBOX_MGMT.SMTP.EDIT.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(
          error.message || this.$t('INBOX_MGMT.SMTP.EDIT.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <SettingsToggleSection
    v-model="isSMTPEnabled"
    :header="$t('INBOX_MGMT.SMTP.WIDGET.HEADER')"
    :description="$t('INBOX_MGMT.SMTP.WIDGET.DESCRIPTION')"
  >
    <template v-if="isSMTPEnabled" #editor>
      <form @submit.prevent="updateInbox">
        <woot-input
          v-model="fromEmail"
          :class="{ error: v$.fromEmail.$error }"
          class="w-full"
          :label="$t('INBOX_MGMT.SMTP.WIDGET.FROM_EMAIL.LABEL')"
          :placeholder="$t('INBOX_MGMT.SMTP.WIDGET.FROM_EMAIL.PLACE_HOLDER')"
          :help-text="$t('INBOX_MGMT.SMTP.WIDGET.FROM_EMAIL.HELP_TEXT')"
          @blur="v$.fromEmail.$touch"
        />
        <woot-input
          v-model="address"
          :class="{ error: v$.address.$error }"
          class="w-full"
          :label="$t('INBOX_MGMT.SMTP.ADDRESS.LABEL')"
          :placeholder="$t('INBOX_MGMT.SMTP.ADDRESS.PLACE_HOLDER')"
          @blur="v$.address.$touch"
        />
        <woot-input
          v-model="port"
          type="number"
          :class="{ error: v$.port.$error }"
          class="w-full"
          :label="$t('INBOX_MGMT.SMTP.PORT.LABEL')"
          :placeholder="$t('INBOX_MGMT.SMTP.PORT.PLACE_HOLDER')"
          @blur="v$.port.$touch"
        />
        <woot-input
          v-model="login"
          :class="{ error: v$.login.$error }"
          class="w-full"
          :label="$t('INBOX_MGMT.SMTP.LOGIN.LABEL')"
          :placeholder="$t('INBOX_MGMT.SMTP.LOGIN.PLACE_HOLDER')"
          @blur="v$.login.$touch"
        />
        <woot-input
          v-model="password"
          :class="{ error: v$.password.$error }"
          class="w-full"
          :label="$t('INBOX_MGMT.SMTP.PASSWORD.LABEL')"
          :placeholder="$t('INBOX_MGMT.SMTP.PASSWORD.PLACE_HOLDER')"
          type="password"
          @blur="v$.password.$touch"
        />
        <woot-input
          v-model="domain"
          :class="{ error: v$.domain.$error }"
          class="w-full"
          :label="$t('INBOX_MGMT.SMTP.DOMAIN.LABEL')"
          :placeholder="$t('INBOX_MGMT.SMTP.DOMAIN.PLACE_HOLDER')"
          @blur="v$.domain.$touch"
        />
        <InputRadioGroup
          :label="$t('INBOX_MGMT.SMTP.ENCRYPTION')"
          :items="encryptionProtocols"
          :action="handleEncryptionChange"
        />
        <SingleSelectDropdown
          class="w-full"
          :label="$t('INBOX_MGMT.SMTP.OPEN_SSL_VERIFY_MODE')"
          :selected="openSSLVerifyMode"
          :options="openSSLVerifyModes"
          :action="handleSSLModeChange"
        />
        <SingleSelectDropdown
          class="w-full"
          :label="$t('INBOX_MGMT.SMTP.AUTH_MECHANISM')"
          :selected="authMechanism"
          :options="authMechanisms"
          :action="handleAuthMechanismChange"
        />
        <div class="mt-3 flex justify-end">
          <NextButton
            type="submit"
            :label="$t('INBOX_MGMT.SMTP.UPDATE')"
            :is-loading="uiFlags.isUpdatingSMTP"
            :disabled="v$.$invalid || uiFlags.isUpdatingSMTP"
          />
        </div>
      </form>
    </template>
  </SettingsToggleSection>
</template>
