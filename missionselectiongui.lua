DB:create_entry("texture", "ui/atlas/raid_bounty", ModPath .. "assets/bounty.dds")

local original_raid_list_data_source = MissionSelectionGui._raid_list_data_source

function MissionSelectionGui:_raid_list_data_source()
	local raid_list = original_raid_list_data_source(self)

	local daily_mission_name = "tnd"
	local daily_forced_card = "ra_slasher_movie"

	local mission_data = tweak_data.operations:mission_data(daily_mission_name)
	local item_text = self:translate(mission_data.name_id)
	local item_icon_name = mission_data.icon_menu
	local item_icon = {
		texture = "ui/atlas/raid_bounty",
		texture_rect = {
			0,
			0,
			56,
			56
		}
	}
	
	table.insert(raid_list, 1, {
		text = "DAILY BOUNTY: " .. item_text,
		value = daily_mission_name,
		icon = item_icon,
		--color = tweak_data.gui.colors.raid_dark_red,
		--selected_color = tweak_data.gui.colors.raid_red,
		color = tweak_data.gui.colors.raid_white,
		selected_color = tweak_data.gui.colors.raid_red,
		breadcrumb = {
			category = BreadcrumbManager.CATEGORY_NEW_RAID,
			identifiers = {
				daily_mission_name
			}
		},
		debug = mission_data.debug,
		unlocked = true,
		daily = {
			challenge_card = daily_forced_card,
			reward = 25
		}
	})

	return raid_list
end

function MissionSelectionGui:_animate_hide_card()
	local duration = 0.25
	local t = self._card_animation_t * duration

	while t < duration do
		local dt = coroutine.yield()
		t = t + dt
		local setting_alpha = Easing.cubic_in_out(t, 1, -1, duration)

		self._card_panel:set_alpha(setting_alpha)

		self._card_animation_t = t / duration
	end

	self._card_panel:set_alpha(0)
	self._card_panel:set_visible(false)

	self._card_animation_t = 1
end

function MissionSelectionGui:_animate_show_card()
	local duration = 0.25
	local t = (1 - self._card_animation_t) * duration

	self._card_panel:set_visible(true)

	while t < duration do
		local dt = coroutine.yield()
		t = t + dt
		local setting_alpha = Easing.cubic_in_out(t, 0, 1, duration)

		self._card_panel:set_alpha(setting_alpha)

		self._card_animation_t = 1 - t / duration
	end

	self._card_panel:set_alpha(1)

	self._card_animation_t = 0
end

Hooks:PostHook(MissionSelectionGui, "_layout_settings", "daily_raid_layout_settings", function(self)
	self._card_animation_t = 1
	local card_panel_params = {
		name = "card_panel"
	}
	self._card_panel = self._settings_panel:panel(card_panel_params)

	local width = 197
	local height = 267
	local card_y = 375
	local card_details_params = {
		name = "card_details",
		visible = true,
		x = 0,
		y = card_y,
		w = width,
		h = height,
		card_x = 0,
		card_y = 0,
		card_w = width,
		card_h = height
	}
	self._card_details = self._card_panel:create_custom_control(RaidGUIControlCardDetails, card_details_params)

	local text_info_pos = width + 25

	local params_card_title_right = {
		name = "card_title_label_right",
		h = 72,
		wrap = true,
		w = 255,
		align = "left",
		vertical = "left",
		text = "Forced Challenge Card",
		y = card_y,
		x = text_info_pos,
		color = tweak_data.gui.colors.raid_red,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = 26
	}
	self._card_title_label_right = self._card_panel:label(params_card_title_right)

	local params_card_name_right = {
		name = "card_name_label_right",
		h = 72,
		wrap = true,
		w = 255,
		align = "left",
		vertical = "left",
		text = "DON'T YOU DIE ON ME",
		y = card_y + 30,
		x = text_info_pos,
		color = tweak_data.gui.colors.white,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = 26
	}
	self._card_name_label_right = self._card_panel:label(params_card_name_right)

	local bonus_y = card_y + 80
	local malus_y = bonus_y + 75

	local desc_x = text_info_pos + 65

	self._bonus_effect_icon = self._card_panel:image({
		name = "bonus_effect_icon",
		h = 64,
		w = 64,
		visible = true,
		x = text_info_pos,
		y = bonus_y,
		texture = tweak_data.gui.icons.ico_bonus.texture,
		texture_rect = tweak_data.gui.icons.ico_bonus.texture_rect
	})
	self._bonus_effect_label = self._card_panel:label({
		w = 220,
		name = "bonus_effect_label",
		h = 64,
		wrap = true,
		align = "left",
		vertical = "center",
		text = "Your mother is gay",
		x = desc_x,
		y = bonus_y,
		font = tweak_data.gui.fonts.lato,
		font_size = 16,
		color = tweak_data.gui.colors.raid_grey
	})
	self._malus_effect_icon = self._card_panel:image({
		name = "malus_effect_icon",
		h = 64,
		w = 64,
		visible = true,
		x = text_info_pos,
		y = malus_y,
		texture = tweak_data.gui.icons.ico_malus.texture,
		texture_rect = tweak_data.gui.icons.ico_malus.texture_rect
	})
	self._malus_effect_label = self._card_panel:label({
		w = 220,
		name = "malus_effect_label",
		h = 64,
		wrap = true,
		align = "left",
		vertical = "center",
		text = "So are you",
		x = desc_x,
		y = malus_y,
		font = tweak_data.gui.fonts.lato,
		font_size = 16,
		color = tweak_data.gui.colors.raid_grey
	})
end)

function MissionSelectionGui:_on_raid_clicked(raid_data)
	if raid_data.daily ~= self._daily or self._selected_job_id ~= raid_data.value then
		self:_stop_mission_briefing_audio()
	else
		return
	end

	self._daily = raid_data.daily

	local difficulty_available = managers.progression:get_mission_progression(tweak_data.operations.missions[raid_data.value].job_type, raid_data.value)

	if difficulty_available and difficulty_available < tweak_data:difficulty_to_index(self._difficulty_stepper:get_value()) then
		self._difficulty_stepper:set_value_and_render(tweak_data:index_to_difficulty(difficulty_available), true)
		self:_check_difficulty_warning()
	end

	self._operation_tutorialization_panel:get_engine_panel():stop()
	self._operation_tutorialization_panel:get_engine_panel():animate(callback(self, self, "_animate_hide_operation_tutorialization"))

	self._selected_job_id = raid_data.value
	self._selected_new_operation_index = nil

	local job_tweak_data = tweak_data.operations.missions[self._selected_job_id]

	if not managers.progression:mission_unlocked(job_tweak_data.job_type, self._selected_job_id) and not job_tweak_data.consumable and not job_tweak_data.debug and not raid_data.daily then
		if Network:is_server() then
			self._start_disabled_message:set_text(self:translate("raid_locked_progression", true))
			self._start_disabled_message:set_visible(true)
			self._raid_start_button:set_visible(false)
		end

		self:_on_locked_raid_clicked()
	else
		if Network:is_server() then
			self._start_disabled_message:set_visible(false)
			self._raid_start_button:set_visible(true)
		end

		local difficulty_available, difficulty_completed = 0, 0
		if not raid_data.daily then
			difficulty_available, difficulty_completed = managers.progression:get_mission_progression(OperationsTweakData.JOB_TYPE_RAID, self._selected_job_id)

			self:set_difficulty_stepper_data(difficulty_available, difficulty_completed)
		else
			self._difficulty_stepper:set_disabled_items({false, false, true, false})
			self._difficulty_stepper:set_value_and_render("difficulty_3", true)
		end

		local raid_tweak_data = tweak_data.operations.missions[raid_data.value]

		self._primary_paper_mission_icon:set_image(tweak_data.gui.icons[raid_tweak_data.icon_menu].texture)
		self._primary_paper_mission_icon:set_texture_rect(unpack(tweak_data.gui.icons[raid_tweak_data.icon_menu].texture_rect))
		self._primary_paper_mission_icon:set_w(tweak_data.gui:icon_w(raid_tweak_data.icon_menu))
		self._primary_paper_mission_icon:set_h(tweak_data.gui:icon_h(raid_tweak_data.icon_menu))
		self._primary_paper_title:set_text(self:translate(raid_tweak_data.name_id, true))

		if job_tweak_data.consumable then
			self._primary_paper_subtitle:set_visible(true)
			self._primary_paper_subtitle:set_text(self:translate("menu_mission_selected_mission_type_consumable", true))
			self._primary_paper_difficulty_indicator:set_visible(false)
		elseif raid_data.daily then
			self._primary_paper_subtitle:set_visible(true)
			self._primary_paper_subtitle:set_text("DAILY RAID")
			self._primary_paper_difficulty_indicator:set_visible(false)
		elseif difficulty_available and difficulty_completed then
			self._primary_paper_subtitle:set_visible(false)
			self._primary_paper_difficulty_indicator:set_visible(true)
			self._primary_paper_difficulty_indicator:set_progress(difficulty_available, difficulty_completed)
		end

		if raid_data.daily then
			self._card_panel:animate(callback(self, self, "_animate_show_card"))

			local card_data = tweak_data.challenge_cards:get_card_by_key_name(raid_data.daily.challenge_card)
			local bonus_description, malus_description = managers.challenge_cards:get_card_description(raid_data.daily.challenge_card)

			self._card_details:set_card(raid_data.daily.challenge_card)
			self._card_name_label_right:set_text(self:translate(card_data.name))
			self._bonus_effect_label:set_text(bonus_description)
			self._malus_effect_label:set_text(malus_description)
		else
			self._card_panel:animate(callback(self, self, "_animate_hide_card"))
		end

		local stamp_texture = tweak_data.gui.icons[MissionSelectionGui.PAPER_STAMP_ICON]

		if raid_tweak_data.consumable then
			stamp_texture = tweak_data.gui.icons[MissionSelectionGui.PAPER_STAMP_ICON_CONSUMABLE]
		end

		self._soe_emblem:set_image(stamp_texture.texture)
		self._soe_emblem:set_texture_rect(unpack(stamp_texture.texture_rect))
		self._info_button:set_active(true)
		self._intel_button:set_active(false)
		self._audio_button:set_active(false)
		self._info_button:enable()
		self._intel_button:enable()

		if raid_tweak_data.consumable then
			self._audio_button:hide()
		else
			self._audio_button:show()
			self._audio_button:enable()
		end

		self:_on_info_clicked(nil, true)
		self._intel_image_grid:clear_selection()
		self:_stop_mission_briefing_audio()

		local short_audio_briefing_id = raid_tweak_data.short_audio_briefing_id

		if short_audio_briefing_id then
			managers.queued_tasks:queue("play_short_audio_briefing", self.play_short_audio_briefing, self, short_audio_briefing_id, 1, nil)
		end
	end
end

function MissionSelectionGui:_check_difficulty_warning()
	if self._selected_job_id and tweak_data.operations.missions[self._selected_job_id].consumable then
		self._difficulty_warning_panel:get_engine_panel():stop()
		self._difficulty_warning_panel:get_engine_panel():animate(callback(self, self, "_animate_slide_out_difficulty_warning_message"))
		self._raid_start_button:enable()
		self._difficulty_warning:stop()
		self._difficulty_warning:animate(callback(self, self, "_animate_hide_difficulty_warning_message"))

		return
	elseif not self._selected_job_id or not managers.progression:mission_unlocked(tweak_data.operations.missions[self._selected_job_id].job_type, self._selected_job_id) then
		if not self._daily then
			return
		end
	end

	local difficulty_available, difficulty_completed = 99, 0
	local difficulty = tweak_data:difficulty_to_index(self._difficulty_stepper:get_value())

	if not self._daily then
		difficulty_available, difficulty_completed = managers.progression:get_mission_progression(tweak_data.operations.missions[self._selected_job_id].job_type, self._selected_job_id)
	end

	if (difficulty_available < difficulty) or (self._daily and difficulty ~= 3) then
		local message = ""
		if difficulty_available < difficulty then
			message = managers.localization:text("raid_difficulty_warning", {
				TARGET_DIFFICULTY = managers.localization:text("menu_difficulty_" .. tostring(difficulty)),
				NEEDED_DIFFICULTY = managers.localization:text("menu_difficulty_" .. tostring(difficulty - 1))
			})
		else
			message = "Daily Raid can only be played on HARD difficulty"
		end

		self._difficulty_warning_panel:get_engine_panel():stop()
		self._difficulty_warning_panel:get_engine_panel():animate(callback(self, self, "_animate_slide_in_difficulty_warning_message"), message)
		self._raid_start_button:disable()
		self._difficulty_warning:stop()
		self._difficulty_warning:animate(callback(self, self, "_animate_set_difficulty_warning_message"), message)

		if self._current_mission_type == "raids" then
			self:_bind_locked_raid_controller_inputs()
		elseif self._current_mission_type == "operations" and self._current_display == MissionSelectionGui.DISPLAY_SECOND then
			self:_bind_locked_operation_list_controller_inputs()
		elseif self._current_mission_type == "operations" and self._current_display == MissionSelectionGui.DISPLAY_FIRST then
			self:_bind_operation_list_controller_inputs()
		end
	else
		self._difficulty_warning_panel:get_engine_panel():stop()
		self._difficulty_warning_panel:get_engine_panel():animate(callback(self, self, "_animate_slide_out_difficulty_warning_message"))
		self._raid_start_button:enable()
		self._difficulty_warning:stop()
		self._difficulty_warning:animate(callback(self, self, "_animate_hide_difficulty_warning_message"))

		if self._current_mission_type == "raids" then
			self:_bind_raid_controller_inputs()
		elseif self._current_mission_type == "operations" then
			self:_bind_operation_list_controller_inputs()
		end
	end
end

Hooks:PostHook(MissionSelectionGui, "_start_job", "daily_raid_start_job", function(self, job_id)
	if Network:is_server() and self._daily then
		managers.challenge_cards.forced_card = self._daily.challenge_card
		managers.challenge_cards.reward = self._daily.reward
	else
		managers.challenge_cards.forced_card = nil
		managers.challenge_cards.reward = nil
	end
end)