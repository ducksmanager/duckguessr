<template>
  <b-alert v-if="!username" show variant="warning">
    You are not connected
  </b-alert>
  <b-card-group v-else deck>
    <b-card
      v-for="(label, url) in cards"
      :key="url"
      :title="label"
      img-src="https://picsum.photos/600/300/?image=25"
      :img-alt="label"
      img-top
      align="center"
      @click="$router.push(`/setup/${url}`)"
    />
  </b-card-group>
</template>

<script>
import useUser from '../components/user'
import { defineComponent } from '#imports'

export default defineComponent({
  setup() {
    return {
      username: useUser().username,
      cards: {
        any: 'All creators',
        us: 'US artists',
      },
    }
  },
})
</script>

<style scoped lang="scss">
.card {
  color: black;
  cursor: pointer;
}
</style>
