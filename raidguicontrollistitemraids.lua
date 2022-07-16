Hooks:PostHook(RaidGUIControlListItemRaids, "init", "daily_raid_reward_display", function(self, parent, params, data)
	if self._data.daily then
		self._difficulty_indicator:hide()
		self:_layout_consumable_mission_label()
		self._consumable_mission_label:set_text("REWARD: " ..  self._data.daily.reward .. " GOLD BARS")
		local _, _, w, h = self._consumable_mission_label:text_rect()
		self._consumable_mission_label:set_w(w)
		self._consumable_mission_label:set_h(h)
		self._consumable_mission_label:set_center_y(RaidGUIControlListItemRaids.DIFFICULTY_CENTER_Y)
		self._consumable_mission_label:stop()
		self._consumable_mission_label:set_color(Color("eaeef4"))
		self._consumable_mission_label:animate(UIAnimation.animate_text_glow, Color("d9e3fa"), 1.5, 0.04, 1.4)

		self._item_icon:set_color(tweak_data.gui.colors.raid_red)
	end
end)