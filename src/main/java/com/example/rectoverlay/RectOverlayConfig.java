/*
 * Copyright (c) 2024, TechDevGroup
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package com.example.rectoverlay;

import java.awt.Color;
import net.runelite.client.config.Alpha;
import net.runelite.client.config.Config;
import net.runelite.client.config.ConfigGroup;
import net.runelite.client.config.ConfigItem;
import net.runelite.client.config.Range;

@ConfigGroup("rectoverlay")
public interface RectOverlayConfig extends Config
{
	@ConfigItem(
		keyName = "rectWidth",
		name = "Width",
		description = "Width of the rectangle in pixels",
		position = 1
	)
	@Range(min = 10, max = 500)
	default int rectWidth()
	{
		return 120;
	}

	@ConfigItem(
		keyName = "rectHeight",
		name = "Height",
		description = "Height of the rectangle in pixels",
		position = 2
	)
	@Range(min = 10, max = 500)
	default int rectHeight()
	{
		return 80;
	}

	@Alpha
	@ConfigItem(
		keyName = "fillColor",
		name = "Fill Color",
		description = "Fill color of the rectangle (supports transparency via alpha)",
		position = 3
	)
	default Color fillColor()
	{
		return new Color(255, 0, 0, 100);
	}

	@ConfigItem(
		keyName = "borderColor",
		name = "Border Color",
		description = "Border color of the rectangle",
		position = 4
	)
	default Color borderColor()
	{
		return Color.RED;
	}
}
