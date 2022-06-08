<template>
  <div v-if="isAnonymous" class="d-flex align-items-center flex-column">
    <b-alert show variant="warning" class="text-center">
      Vous pouvez seulement choisir un avatar si vous êtes connecté(e).<br />
      {{ t('Log in on DucksManager then refresh this page to be able to choose your avatar :-)') }}
    </b-alert>
  </div>
  <div v-else class="d-flex justify-content-center flex-column">
    <b-row class="justify-content-center">
      <b-col cols="9" class="d-flex justify-content-center">
        <b-alert show variant="info" class="text-center">
          <div>
            {{ t('Choose an avatar among the characters of the Donald Duck family tree.') }}
          </div>
          <div>
            {{ t('Some avatars can be unlocked by earning Duckguessr medals.') }}
          </div>
        </b-alert>
      </b-col>
    </b-row>
    <b-row class="justify-content-center">
      <b-col cols="9" class="justify-content-center px-0">
        <img
          ref="tree"
          src="/Donald_Duck_Family_Tree.webp"
          @mousemove="onMouseMove"
          @load="onTreeLoad"
        />
        <div
          v-if="currentAvatar"
          class="position-absolute avatar selected"
          :style="{
            left: `${currentAvatar.localPosition[0]}px`,
            top: `${currentAvatar.localPosition[1]}px`,
            width: `${avatarSize}px`,
            height: `${avatarSize}px`,
          }"
        />
        <div
          v-if="closestAvatar"
          class="position-absolute avatar"
          :style="{
            left: `${closestAvatar.localPosition[0]}px`,
            top: `${closestAvatar.localPosition[1]}px`,
            width: `${avatarSize}px`,
            height: `${avatarSize}px`,
          }"
          @click="onSelectAvatar"
        />
      </b-col>
    </b-row>
  </div>
</template>

<script lang="ts" setup>
import { computed, ref, watch } from '@nuxtjs/composition-api'
import { useI18n } from 'nuxt-i18n-composable'
import Index from '@prisma/client'
import { Avatar } from '~/types/avatars'
import { userStore } from '~/store/user'
const { t } = useI18n()

const isAnonymous = computed(() => userStore().isAnonymous)

const { avatars, avatarDiskDiameter } = require('~/types/avatars.ts')
const tree = ref(null as any | null)

const treeImageNaturalWidth = ref(null as number | null)

interface AvatarWithLocalPosition extends Avatar {
  localPosition: number[] | null
}

const currentAvatar = ref(null as AvatarWithLocalPosition | null)
const closestAvatar = ref(null as AvatarWithLocalPosition | null)
const avatarSize = ref(null as number | null)

const calculateLocalPosition = (avatar: AvatarWithLocalPosition | null) => {
  if (!avatar) {
    return
  }
  const treeImageRatio = treeImageNaturalWidth.value! / tree.value!.width
  avatarSize.value = avatarDiskDiameter / treeImageRatio
  avatar.localPosition = avatar.position.map(
    (coordinate) => coordinate / treeImageRatio - avatarSize.value! / 2
  )
}

watch(
  () => closestAvatar.value,
  (avatar) => {
    calculateLocalPosition(avatar)
  },
  {
    immediate: true,
  }
)

watch(
  () => userStore().user?.avatar,
  (avatarName) => {
    currentAvatar.value = avatars.find(({ character }: Avatar) => character === avatarName)
    calculateLocalPosition(currentAvatar.value)
  }
)

const onMouseMove = ({ clientX, clientY, target }: any) => {
  const rect = target.getBoundingClientRect()
  const position = [clientX - rect.left, clientY - rect.top]
  const positionUsingNaturalDimensions = position.map(
    (coordinate) => coordinate * (treeImageNaturalWidth.value! / rect.width)
  )

  closestAvatar.value =
    avatars.find(
      ({ position: characterCoordinates }: Avatar) =>
        Math.sqrt(
          Math.pow(positionUsingNaturalDimensions[0] - characterCoordinates[0], 2) +
            Math.pow(positionUsingNaturalDimensions[1] - characterCoordinates[1], 2)
        ) <
        avatarDiskDiameter / 2
    ) || null
}

const onTreeLoad = (event: any) => {
  if (event) {
    treeImageNaturalWidth.value = event.target.naturalWidth
  }
}

const onSelectAvatar = () => {
  userStore().user!.avatar = closestAvatar.value!.character
  userStore().loginSocket!.emit('updateUser', userStore().user!, (updatedUser: Index.player) => {
    userStore().user = updatedUser
  })
}
</script>

<style scoped lang="scss">
img {
  width: 100%;
}

.avatar {
  border-radius: 100%;
  outline: 10px solid lightgrey;
  cursor: pointer;

  &.selected {
    outline: 10px solid darkgrey;
  }
}
</style>