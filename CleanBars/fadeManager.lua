local FadeManager = {}
CleanBars.FadeManager = FadeManager

local FadeWatcher = CreateFrame('Frame')
local Fader = CreateFrame('Frame')

function FadeManager:Add(f)
	FadeWatcher:Add(f)
end

function FadeManager:Remove(f)
	FadeWatcher:Remove(f)
end

do
	local watchedFrames = {}

	FadeWatcher:Hide()
	FadeWatcher.nextUpdate = 0
	FadeWatcher.DELAY = 0.12

	FadeWatcher:SetScript('OnUpdate', function(self, elapsed)
		if not next(watchedFrames) then
			self:Hide()
		end

		self.nextUpdate = self.nextUpdate - elapsed
		if self.nextUpdate < 0 then
			self.nextUpdate = self.DELAY
			for f in pairs(watchedFrames) do
				local expectedAlpha, currentAlpha = f:GetExpectedAlpha(), f:GetAlpha()
				if abs(expectedAlpha - currentAlpha) > 0.01 then
					Fader:Fade(f, 0.1, currentAlpha, expectedAlpha)
				end
			end
		end
	end)

	FadeWatcher:SetScript('OnHide', function(self)
		self.nextUpdate = 0
	end)

	function FadeWatcher:Add(f)
		watchedFrames[f] = true
		self:Show()
	end

	function FadeWatcher:Remove(f)
		watchedFrames[f] = nil
	end
end

do
	local fadingFrames = {}

	Fader:Hide()

	Fader:SetScript('OnUpdate', function(self, elapsed)
		if not next(fadingFrames) then
			self:Hide()
		end

		for frame, fadeInfo in pairs(fadingFrames) do
			fadeInfo.fadeTimer = (fadeInfo.fadeTimer or 0) + elapsed

			if fadeInfo.fadeTimer < fadeInfo.timeToFade then
				local pct = fadeInfo.fadeTimer / fadeInfo.timeToFade
				local delta = fadeInfo.endAlpha - fadeInfo.startAlpha

				frame:SetAlpha(fadeInfo.startAlpha + pct*delta)
			else
				frame:SetAlpha(fadeInfo.endAlpha)
				fadingFrames[frame] = nil
			end
		end
	end)

	function Fader:Fade(frame, timeToFade, startAlpha, endAlpha)
		frame:SetAlpha(startAlpha)

		if not fadingFrames[frame] then
			local fadeInfo = frame.fadeInfo or {}
			fadeInfo.timeToFade = timeToFade
			fadeInfo.startAlpha = startAlpha
			fadeInfo.endAlpha = endAlpha
			fadeInfo.fadeTimer = 0
			frame.fadeInfo = fadeInfo
			
			fadingFrames[frame] = fadeInfo
			self:Show()
		end
	end
end
