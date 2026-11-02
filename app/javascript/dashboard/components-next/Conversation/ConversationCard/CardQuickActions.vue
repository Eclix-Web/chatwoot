<script setup>
import { useI18n } from 'vue-i18n';
import wootConstants from 'dashboard/constants/globals';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  status: { type: String, required: true },
});

const emit = defineEmits(['updateStatus']);

const { t } = useI18n();
const { RESOLVED, ARCHIVED } = wootConstants.STATUS_TYPE;
</script>

<template>
  <div
    class="hidden group-hover:flex items-center gap-0.5 p-0.5 rounded-lg bg-n-solid-2 outline outline-1 outline-n-weak shadow-sm"
    @click.stop
  >
    <Button
      v-if="status !== RESOLVED"
      v-tooltip.top="t('CONVERSATION.CARD_CONTEXT_MENU.RESOLVED')"
      icon="i-lucide-check-check"
      ghost
      slate
      xs
      @click="emit('updateStatus', RESOLVED)"
    />
    <Button
      v-if="status !== ARCHIVED"
      v-tooltip.top="t('CONVERSATION.CARD_CONTEXT_MENU.ARCHIVE')"
      icon="i-lucide-archive"
      ghost
      slate
      xs
      @click="emit('updateStatus', ARCHIVED)"
    />
  </div>
</template>
